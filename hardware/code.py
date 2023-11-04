import time
import board
from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService
from analogio import AnalogIn

analog_in = AnalogIn(board.A1)

ble = BLERadio()
uart = UARTService()
advertisment = ProvideServicesAdvertisement(uart)
ble.name = "fishingRod"

data_points = []
num_data_wanted = 10
threshold_value =  1.6

def get_avg(data_list):
    result = 0
    for data in data_list:
        result = result + data

    return result / len(data_list)

def get_voltage(pin):
    #return (pin.value)
    return (pin.value * 3.3) / 65536



while True:
    ble.start_advertising(advertisment)
    i = 0
    while not ble.connected:
        print("not connected: ", ble.name)
        i = i + 1
        print(i)
        time.sleep(0.1)

    ble.stop_advertising()
    data_points = []

    while ble.connected:
        x = get_voltage(analog_in)

#        uart.write("10")

        if len(data_points) < num_data_wanted :
            data_points.append(x)
            print('gathering more data points')
        else:
            data_points.append(x)
            if len(data_points) > num_data_wanted:
                data_points.pop(0)

            avg = get_avg(data_points)

            print((x,avg))
            uart.write("{},{}".format(x,avg))



            if avg > threshold_value:
                print("shake triggered")


        time.sleep(0.5)

