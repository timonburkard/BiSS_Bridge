import sys
import serial
import serial.tools.list_ports
import threading
import time
from collections import deque
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                             QHBoxLayout, QLabel, QComboBox, QPushButton,
                             QGroupBox, QFrame, QStyleFactory)
from PyQt5.QtCore import QTimer, Qt
from PyQt5.QtGui import QColor, QPalette, QFont
import matplotlib.pyplot as plt
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas

import queue

class SerialReader:
    def __init__(self):
        self.serial_port = None
        self.running = False
        self.thread = None
        self.data_lock = threading.Lock()
        self.latest_data = None
        self.history = deque(maxlen=100) # Store last 100 points for plotting
        self.timestamps = deque(maxlen=100)

    def connect(self, port, baudrate):
        try:
            self.serial_port = serial.Serial(port, baudrate, timeout=1)
            self.running = True
            self.thread = threading.Thread(target=self._read_loop, daemon=True)
            self.thread.start()
            return True
        except Exception as e:
            print(f"Error connecting to {port}: {e}")
            return False

    def disconnect(self):
        self.running = False
        if self.thread:
            self.thread.join(timeout=1.0)
        if self.serial_port and self.serial_port.is_open:
            self.serial_port.close()

    def _read_loop(self):
        raise NotImplementedError

class PrimaryDeviceReader(SerialReader):
    def _read_loop(self):
        while self.running and self.serial_port.is_open:
            try:
                line = self.serial_port.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    # Expected format: position, error_bit, warning_bit, crc_fail_bit
                    parts = line.split(',')
                    if len(parts) >= 4:
                        try:
                            pos = int(parts[0].strip())
                            err = int(parts[1].strip())
                            warn = int(parts[2].strip())
                            crc = int(parts[3].strip())

                            with self.data_lock:
                                self.latest_data = {
                                    'pos': pos,
                                    'err': err,
                                    'warn': warn,
                                    'crc': crc
                                }
                                self.history.append(pos)
                                self.timestamps.append(time.time())
                        except ValueError:
                            pass
            except Exception as e:
                print(f"Primary read error: {e}")
                time.sleep(0.1)

class SecondaryDeviceReader(SerialReader):
    def __init__(self):
        super().__init__()
        self.command_queue = queue.Queue()
        self.ref_status = ""

    def trigger_ref(self):
        self.command_queue.put("REF")

    def send_command(self, cmd):
        self.command_queue.put(cmd)

    def _read_loop(self):
        last_pos = None
        stable_start_time = None

        while self.running and self.serial_port.is_open:
            try:
                while not self.command_queue.empty():
                    cmd = self.command_queue.get()
                    if cmd == "REF":
                        self.ref_status = "Sending REF..."
                        self.serial_port.write(b"REF\r")
                        time.sleep(0.1)
                        self.ref_status = "Waiting for stability..."
                        last_pos = None
                        stable_start_time = None
                    else:
                        self.serial_port.write(cmd.encode('utf-8') + b'\r')
                        time.sleep(0.1)

                # Send command
                self.serial_port.write(b"TP\r")

                # Read response
                start_time = time.time()
                response_found = False

                while (time.time() - start_time) < 0.2: # 200ms timeout for response
                    if self.serial_port.in_waiting:
                        line = self.serial_port.readline().decode('utf-8', errors='ignore').strip()
                        if line and not 'tp' in line.lower() and line.isdigit():
                            pos = int(line)
                            pos = (pos - 78460) * -1
                            with self.data_lock:
                                self.latest_data = {'pos': pos}
                                self.history.append(pos)
                                self.timestamps.append(time.time())
                            response_found = True

                            if self.ref_status == "Waiting for stability...":
                                if last_pos is not None and abs(pos - last_pos) <= 1:
                                    if stable_start_time is None:
                                        stable_start_time = time.time()
                                    elif time.time() - stable_start_time > 1.0:
                                        self.ref_status = "Stable"
                                else:
                                    stable_start_time = None
                                last_pos = pos

                            break
                    else:
                        time.sleep(0.01)

                if not response_found:
                    self.serial_port.reset_input_buffer()

                time.sleep(0.1) # Poll interval
            except Exception as e:
                print(f"Secondary read error: {e}")
                self.ref_status = f"Error: {e}"
                time.sleep(0.5)

class StatusIndicator(QLabel):
    def __init__(self, text):
        super().__init__()
        self.setFixedSize(20, 20)
        self.setStyleSheet("background-color: gray; border: 1px solid black; border-radius: 10px;")
        self.setToolTip(text)

    def set_status(self, active):
        color = "red" if active else "green"
        self.setStyleSheet(f"background-color: {color}; border: 1px solid black; border-radius: 10px;")

class MonitorApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("BiSS Bridge Monitor Tool")
        self.resize(1000, 800)

        self.primary_reader = PrimaryDeviceReader()
        self.secondary_reader = SecondaryDeviceReader()

        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.main_layout = QVBoxLayout(self.central_widget)

        self.setup_ui()
        self.update_ports()

        self.timer = QTimer()
        self.timer.timeout.connect(self.update_gui)
        self.timer.start(100)

    def setup_ui(self):
        # Control Panel
        control_group = QGroupBox("Connection Settings")
        control_layout = QHBoxLayout()
        control_group.setLayout(control_layout)
        self.main_layout.addWidget(control_group)

        # Primary Device
        control_layout.addWidget(QLabel("Primary Device (CSV):"))
        self.primary_combo = QComboBox()
        self.primary_combo.setMinimumWidth(150)
        control_layout.addWidget(self.primary_combo)

        self.btn_connect_primary = QPushButton("Connect")
        self.btn_connect_primary.clicked.connect(self.toggle_primary)
        control_layout.addWidget(self.btn_connect_primary)

        control_layout.addSpacing(20)

        # Secondary Device
        control_layout.addWidget(QLabel("Secondary Device (TP):"))
        self.secondary_combo = QComboBox()
        self.secondary_combo.setMinimumWidth(150)
        control_layout.addWidget(self.secondary_combo)

        self.btn_connect_secondary = QPushButton("Connect")
        self.btn_connect_secondary.clicked.connect(self.toggle_secondary)
        control_layout.addWidget(self.btn_connect_secondary)

        self.btn_ref = QPushButton("REF")
        self.btn_ref.clicked.connect(self.send_ref)
        control_layout.addWidget(self.btn_ref)

        self.btn_go_zero = QPushButton("Go Zero")
        self.btn_go_zero.clicked.connect(lambda: self.send_secondary_cmd("G78460"))
        control_layout.addWidget(self.btn_go_zero)

        self.btn_start = QPushButton("Start")
        self.btn_start.clicked.connect(lambda: self.send_secondary_cmd("RR9999"))
        control_layout.addWidget(self.btn_start)

        self.btn_stop = QPushButton("Stop")
        self.btn_stop.clicked.connect(lambda: self.send_secondary_cmd("SM"))
        control_layout.addWidget(self.btn_stop)

        control_layout.addSpacing(20)

        btn_refresh = QPushButton("Refresh Ports")
        btn_refresh.clicked.connect(self.update_ports)
        control_layout.addWidget(btn_refresh)

        control_layout.addStretch()

        # Status Panel
        status_group = QGroupBox("Primary Device Status")
        status_layout = QHBoxLayout()
        status_group.setLayout(status_layout)
        self.main_layout.addWidget(status_group)

        # Indicators
        self.ind_error = self.add_status_indicator(status_layout, "Error Bit")
        self.ind_warning = self.add_status_indicator(status_layout, "Warning Bit")
        self.ind_crc = self.add_status_indicator(status_layout, "CRC Fail")

        status_layout.addSpacing(40)

        # Values
        font = QFont("Consolas", 12)
        font.setBold(True)

        self.lbl_pos_primary = QLabel("Pos: N/A")
        self.lbl_pos_primary.setFont(font)
        status_layout.addWidget(self.lbl_pos_primary)

        status_layout.addSpacing(20)

        self.lbl_pos_secondary = QLabel("Sec Pos: N/A")
        self.lbl_pos_secondary.setFont(font)
        status_layout.addWidget(self.lbl_pos_secondary)

        self.lbl_ref_status = QLabel("")
        status_layout.addWidget(self.lbl_ref_status)

        status_layout.addStretch()

        # Plot
        self.fig, self.ax = plt.subplots(figsize=(5, 4), dpi=100)
        self.ax.set_title("Position Data")
        self.ax.set_xlabel("Time (s)")
        self.ax.set_ylabel("Position")
        self.ax.grid(True)

        self.line_primary, = self.ax.plot([], [], label='Primary', color='blue')
        self.line_secondary, = self.ax.plot([], [], label='Secondary', color='orange')
        self.ax.legend()

        self.canvas = FigureCanvas(self.fig)
        self.main_layout.addWidget(self.canvas)

    def add_status_indicator(self, layout, text):
        container = QWidget()
        h_layout = QHBoxLayout(container)
        h_layout.setContentsMargins(0, 0, 0, 0)

        label = QLabel(text)
        indicator = StatusIndicator(text)

        h_layout.addWidget(label)
        h_layout.addWidget(indicator)

        layout.addWidget(container)
        layout.addSpacing(10)
        return indicator

    def update_ports(self):
        ports = [p.device for p in serial.tools.list_ports.comports()]
        current_primary = self.primary_combo.currentText()
        current_secondary = self.secondary_combo.currentText()

        self.primary_combo.clear()
        self.primary_combo.addItems(ports)
        self.secondary_combo.clear()
        self.secondary_combo.addItems(ports)

        if current_primary in ports:
            self.primary_combo.setCurrentText(current_primary)
        if current_secondary in ports:
            self.secondary_combo.setCurrentText(current_secondary)

    def toggle_primary(self):
        if not self.primary_reader.running:
            port = self.primary_combo.currentText()
            if not port: return
            if self.primary_reader.connect(port, 115200):
                self.btn_connect_primary.setText("Disconnect")
                self.primary_combo.setEnabled(False)
        else:
            self.primary_reader.disconnect()
            self.btn_connect_primary.setText("Connect")
            self.primary_combo.setEnabled(True)

    def toggle_secondary(self):
        if not self.secondary_reader.running:
            port = self.secondary_combo.currentText()
            if not port: return
            if self.secondary_reader.connect(port, 115200):
                self.btn_connect_secondary.setText("Disconnect")
                self.secondary_combo.setEnabled(False)
        else:
            self.secondary_reader.disconnect()
            self.btn_connect_secondary.setText("Connect")
            self.secondary_combo.setEnabled(True)

    def send_ref(self):
        if self.secondary_reader.running:
            self.secondary_reader.trigger_ref()

    def send_secondary_cmd(self, cmd):
        if self.secondary_reader.running:
            self.secondary_reader.send_command(cmd)

    def update_gui(self):
        # Update Status Indicators
        with self.primary_reader.data_lock:
            data = self.primary_reader.latest_data
            if data:
                self.ind_error.set_status(data['err'])
                self.ind_warning.set_status(data['warn'])
                self.ind_crc.set_status(data['crc'])
                self.lbl_pos_primary.setText(f"Pos: {data['pos']}")

        with self.secondary_reader.data_lock:
            data = self.secondary_reader.latest_data
            if data:
                self.lbl_pos_secondary.setText(f"Sec Pos: {data['pos']}")

        self.lbl_ref_status.setText(self.secondary_reader.ref_status)

        # Update Plot
        current_time = time.time()

        p_times = []
        p_vals = []
        with self.primary_reader.data_lock:
            p_times = list(self.primary_reader.timestamps)
            p_vals = list(self.primary_reader.history)

        s_times = []
        s_vals = []
        with self.secondary_reader.data_lock:
            s_times = list(self.secondary_reader.timestamps)
            s_vals = list(self.secondary_reader.history)

        if p_times or s_times:
            min_time = current_time - 10

            p_data = [(t-current_time, v) for t, v in zip(p_times, p_vals) if t > min_time]
            s_data = [(t-current_time, v) for t, v in zip(s_times, s_vals) if t > min_time]

            if p_data:
                self.line_primary.set_data(*zip(*p_data))
            if s_data:
                self.line_secondary.set_data(*zip(*s_data))

            self.ax.set_xlim(-10, 0)

            all_vals = [v for _, v in p_data] + [v for _, v in s_data]
            if all_vals:
                min_y, max_y = min(all_vals), max(all_vals)
                margin = (max_y - min_y) * 0.1 if max_y != min_y else 1.0
                self.ax.set_ylim(min_y - margin, max_y + margin)

            self.canvas.draw_idle()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle(QStyleFactory.create('Fusion'))
    window = MonitorApp()
    window.show()
    sys.exit(app.exec_())

