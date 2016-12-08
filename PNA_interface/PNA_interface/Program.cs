using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.IO.Ports;

namespace PNA_interface
{
    class Program
    {   

        static void Main(string[] args)
        {
            //// test VNA
            //string hostname = "A-N5225A-10057";
            //double freq = 5e9;
            //int numPoint = 20;
            //PNA p1 = new PNA(hostname);
            //p1.configMeasurement(freq, numPoint);
            //for (int i = 0; i < numPoint; i++)
            //{
            //    p1.manualTrigger();
            //}
            //float[,] E_comp = p1.outputData();
            //for (int i = 0; i < E_comp.GetLength(0); i++)
            //{
            //    Console.WriteLine(i + ": \t" + E_comp[i, 0] + ",   \t" + E_comp[i, 1] + "j");

            //}

            //// test motor
            //SerialPort controllor_port = new SerialPort();
            //controllor_port.PortName = "COM5";

            //SCX11 cont;
            //try
            //{
            //    controllor_port.Open();
            //    cont = new SCX11(controllor_port);
            //    cont.IncMotor(10.0, 60.0, -20.0);
            //    //cont.IncMotor(1.0, 180.0, 360.0);
            //    cont.GoHome();
            //}
            //catch (Exception e)
            //{
            //    Console.WriteLine("An error occured: {0}", e.Message);
            //}


            // test encoder and electromagnet
            SerialPort arduino_port = new SerialPort();
            arduino_port.PortName = "COM4";
            arduino_port.BaudRate = 250000;
            arduino_port.WriteTimeout = 2000;
            arduino_port.ReadTimeout = 2000;
            Encoder_and_Electromagnet enmag;
            try
            {
                arduino_port.Open();
                enmag = new Encoder_and_Electromagnet(arduino_port);
                enmag.Setup4ActiveEncoderOut(20.0, 0.5);
                enmag.TurnOffEverything();
            }
            catch(Exception e)
            {
                Console.WriteLine("An error occured: {0}", e.Message);
            }
            

        }
    }

}
