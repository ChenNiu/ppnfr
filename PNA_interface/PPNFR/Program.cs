using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.IO.Ports;
using System.Diagnostics;

namespace PPNFR
{
    class Program
    {   

        static void Main(string[] args)
        {
            //// test VNA
            //string hostname = "A-N5225A-10057";
            //double freq = 5e9;
            //int numPoint = 32000;
            //int numTrigger = 50;
            //PNA p1 = new PNA(hostname);
            //p1.configMeasurement(freq, numPoint);
            //var trigger_watch = System.Diagnostics.Stopwatch.StartNew();
            //for (int i = 0; i < numTrigger; i++)
            //{
            //    p1.manualTrigger();
            //}
            //trigger_watch.Stop();
            //Console.WriteLine((float)trigger_watch.ElapsedMilliseconds / (float)numTrigger);

            //var output_watch = System.Diagnostics.Stopwatch.StartNew();
            //float[,] E_comp = p1.outputData(numTrigger);
            //output_watch.Stop();
            //Console.WriteLine(output_watch.ElapsedMilliseconds);

            //for (int i = 0; i < E_comp.GetLength(0); i++)
            //{
            //    Console.WriteLine(i + ": \t" + E_comp[i, 0] + ",   \t" + E_comp[i, 1] + "j");

            //}

            //p1.configMeasurement(freq, numPoint);
            //trigger_watch = System.Diagnostics.Stopwatch.StartNew();
            //for (int i = 0; i < numTrigger; i++)
            //{
            //    p1.manualTrigger();
            //}
            //trigger_watch.Stop();
            //Console.WriteLine((float)trigger_watch.ElapsedMilliseconds / (float)numTrigger);

            //output_watch = System.Diagnostics.Stopwatch.StartNew();
            //E_comp = p1.outputData(numTrigger);
            //output_watch.Stop();
            //Console.WriteLine(output_watch.ElapsedMilliseconds);

            //for (int i = 0; i < E_comp.GetLength(0); i++)
            //{
            //    Console.WriteLine(i + ": \t" + E_comp[i, 0] + ",   \t" + E_comp[i, 1] + "j");

            //}

            ////test motor
            //SerialPort controllor_port = new SerialPort();
            //controllor_port.PortName = "COM5";

            //SCX11 cont;

            //try
            //{
            //    controllor_port.Open();
            //    cont = new SCX11(controllor_port);
            //    cont.print2Console = true;
            //    cont.GoHome();
            //    cont.IncMotorNonBlock(1, 1, -10.0);
            //    int numPf = 100;
            //    var pf_watch = System.Diagnostics.Stopwatch.StartNew();
            //    for (int i = 0; i < numPf; i++)
            //    {
            //        double pf = cont.PositionFeedback();
            //        Console.WriteLine(pf);
            //    }
            //    pf_watch.Stop();
            //    Console.WriteLine((float)pf_watch.ElapsedMilliseconds / (float)numPf);
            //    cont.wait_2_MotionEnd();
            //    //cont.IncMotor(1.0, 180.0, 360.0);
            //    cont.GoHome();

            //}
            //catch (Exception e)
            //{
            //    Console.WriteLine("An error occured: {0}", e.Message);
            //}


            //// test encoder and electromagnet
            //SerialPort arduino_port = new SerialPort();
            //arduino_port.PortName = "COM4";
            //arduino_port.BaudRate = 250000;
            //arduino_port.WriteTimeout = 2000;
            //arduino_port.ReadTimeout = 2000;
            //Encoder_and_Electromagnet enmag;
            //try
            //{
            //    arduino_port.Open();
            //    enmag = new Encoder_and_Electromagnet(arduino_port);
            //    enmag.print2Console = false;
            //    enmag.StartPendulum(20.0);
            //    Console.WriteLine("Push the pendulum arm. Press enter when done.");
            //    Console.ReadLine();
            //    //enmag.Setup4ActiveEncoderOut(20.0, 0.5);
            //    //enmag.WaitTillReturnStart();
            //    //System.Threading.Thread.Sleep(100);
            //    if (enmag.WaitTillPendulumReady())
            //    {
            //        int numPenAng = 300;
            //        Stopwatch pen_watch = new Stopwatch();
            //        pen_watch.Start();
            //        for (int i = 0; i < numPenAng; i++)
            //        {
            //            p1.manualTrigger();
            //            double penAng = enmag.GetInstanceAngle();
            //            Console.WriteLine(penAng);
            //            Console.WriteLine("time: " + pen_watch.Elapsed.TotalMilliseconds);
            //        }
            //        pen_watch.Stop();
            //        Console.WriteLine(pen_watch.Elapsed.TotalMilliseconds);
            //        Console.WriteLine(pen_watch.Elapsed.TotalMilliseconds / (double) numPenAng);
            //    }
            //    enmag.EndPendulum();
            //}
            //catch (Exception e)
            //{
            //    Console.WriteLine("An error occured: {0}", e.Message);
            //}

            // test measurement system
            string hostname = "A-N5225A-10057";
            double freq = 5e9;
            PNA pna = new PNA(hostname);

            SerialPort controllor_port = new SerialPort();
            controllor_port.PortName = "COM5";

            SCX11 motor = new SCX11();

            SerialPort arduino_port = new SerialPort();
            arduino_port.PortName = "COM4";
            arduino_port.BaudRate = 250000;
            //arduino_port.WriteTimeout = 2000;
            //arduino_port.ReadTimeout = 2000;
            Encoder_and_Electromagnet arduino = new Encoder_and_Electromagnet();

            try
            {
                controllor_port.Open();
                motor = new SCX11(controllor_port);
                arduino_port.Open();
                arduino = new Encoder_and_Electromagnet(arduino_port);
            }
            catch (Exception e)
            {
                Console.WriteLine("An error occured: {0}", e.Message);
            }

            Measurement_System ms = new Measurement_System(pna, motor, arduino);
            ms.RunContinuousMeasurement();

            Data_Processor dp = new Data_Processor(ms.IsNormPolarList, ms.S21_MeasLists, ms.MotorAng_MeasLists);
            dp.Print2File();

        }
    }

}
