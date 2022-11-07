import pandas as pd
import plotly.express as px
import streamlit as st
from matplotlib import pyplot as plt
from matplotlib import animation
from matplotlib import style
import serial
import time
import math

from datetime import datetime

run = datetime.now()

mensaje = list()
style.use("fivethirtyeight")

graph = plt.figure()

A = fig.add_subplot(1,2,1)

B = fig.add_subplot(1,2,2)


%-------conexion serial------------------%

ser = serial.Serial('COM4', 9600)
ser.readline()



%-------------ploteo-----------------------%
def ploteo(i):
    d1 = []
    d2 = []
    c_sample = 0
    m_inicial = inicio.minute
    for i in range(0,120):
        datoString = ser.readline().decode("utf-8")
        dat_bi_1 = datoString[:8]
        dat_bi_2 = datoString[9:17]
        adc1 = 0
        adc2 = 0
        vr = 5.04
        
        for i in range (len(dat_bi_1)-1,-1,-1):
            if (dat_bi_1[i-1] == '1' ):
                adc1 += 2**i
            else:
                adc1 += 0
                
                
        for i in range (len(dat_bi_2)-1,-1,-1):
            if (dat_bi_2[i-1] == '1' ):
                adc2 += 2**i
            else:
                adc2 += 0
                
vout1 = round((adc1/(255)) * vr,  2)
vout2 = round((adc2/(255)) * vr, 2)
potencia = round(v1 * v2/10, 2)
factor_de_potencia = round(math.cos (vout1 - vout2), 2)

d1.append(vout1)
d2.append(vout2)
now = datetime.now()
c_sample += 1
cad_final = time.strftime('%d/%m/%y")+", "+ str(now.hour) + ";" + str(now_minute) + ";" + str(now.second) + ";")
                          mensaje.append(cad_final)
                          min_actual = now.minute
                          di = min_actual - m_inicial
                          
                          if di == 1:
                          
                          f = open('C:\\Users\\Benjamin\\Desktop\\Report.txt', 'w')
                          
                          for i in range(len(mensaje[i])):
                          
                            f.write(mensaje[i])
                          f.close()
                          m_inicial = now.minute
                          print(cad_final)
A.clear()
A.set_title("Potencia de volt: " + srt(potencia))
A.set_xlabel("tiempo")
A.set_ylabel("Voltaje")
A.set_ylin([-1,6.5])
                          

B.clear()
B.set_title("Factor: " + srt(Factor potencia))
B.set_xlabel("tiempo")
B.set_ylabel("Corriente")
B.set_ylin([-1,6.5])

try:
                          A.plot(range(0,120), d1)
                          B.plot(range(0,120), d2)
                          
except UnicodeDecodeError:
  pass
                          
                          
                          
ani = animation.FuncAnimation(graph, ploteo, interval = 1)
                          
plt.show()
                          
                          

