using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.IO;
using System.IO.Ports;
using System.Diagnostics;

namespace PPNFR
{
    class Measurement_System
    {

        // pna parameters
        double frequency = Globals.FREQUENCY; //default 10GHz
        int maxNumOfPoint = Globals.MAX_NUM_OF_POINTS;
        double ifbw = Globals.IFBW;

        

        // flag
        bool motor_inMotion = false;
        bool pna_inMeas = false;

        // divices
        PNA pna;
        SCX11 motor;
        Encoder_and_Electromagnet arduino;

        // data storage
        List<int> triggerCountList;
        List<bool> isNormPolarList;
        List<List<PNA_MeasPoint>> pna_MeasList;
        List<List<Arduino_MeasPoint>> penAng_MeasList;
        List<List<Motor_MeasPoint>> motorAng_MeasList;

        // data storage getter
        public List<int> TriggerCountList { get { return this.triggerCountList; } }
        public List<bool> IsNormPolarList { get { return this.isNormPolarList; } }
        public List<List<PNA_MeasPoint>> PNA_MeasList { get { return this.pna_MeasList; } }
        public List<List<Motor_MeasPoint>> MotorAng_MeasList { get { return this.motorAng_MeasList; } }
        public List<List<Arduino_MeasPoint>> PenAng_MeasList { get { return this.penAng_MeasList; } }

        // time stamp
        Stopwatch system_watch = new Stopwatch();
        Stopwatch nop_watch = new Stopwatch();

        // debug
        bool debug = false;
        List<double> penAngDebug;
         
        // constructor
        public Measurement_System(PNA pna, SCX11 motor, Encoder_and_Electromagnet arduino)
        {
            this.pna = pna;
            this.motor = motor;
            this.arduino = arduino;
        }
        

        public void RunContinuousMeasurement()
        {

            //initialize data stroage
            this.triggerCountList = new List<int>();
            this.pna_MeasList = new List<List<PNA_MeasPoint>>();
            this.motorAng_MeasList = new List<List<Motor_MeasPoint>>();
            this.penAng_MeasList = new List<List<Arduino_MeasPoint>>();
            this.isNormPolarList = new List<bool>();


            // setup parameters
            bool isNormPolar;
            double start_speed = Globals.START_SPEED;
            double speed = Globals.SPEED;
            int numOfPartial = (int)Math.Floor(360.0 / Globals.PARTIAL_MEAS_ANGLE);

            // zero pendulum angle
            Console.WriteLine("Make sure the pendulum is at rest. Press enter when done.");
            Console.ReadLine();
            this.arduino.ZeroPendulum();

            // run measurement system nomal
            isNormPolar = true;
            Console.Write("Zeroing AUT...");
            this.motor.GoHome();
            Console.WriteLine("\rAUT zeroed.");
            this.arduino.StartPendulum(Globals.TARGET_ANGLE);
            Console.WriteLine("Make sure Probe is horizontal.");
            Console.WriteLine("Push the pendulum arm. Press enter when done.");
            Console.ReadLine();
            Console.Write("Starting the E_normal measurement. ");

            system_watch.Restart();
            if (this.arduino.WaitTillPendulumReady())
            {
                Console.Write("Pendulum is ready. ");
                
                for(int i = 0; i < numOfPartial; i++)
                {
                    this.RunContinuousMeasurement_Partial(start_speed, speed, Globals.PARTIAL_MEAS_ANGLE, isNormPolar);
                }
            }
            this.arduino.EndPendulum();
            Console.WriteLine("\rFinished the E_normal measurement.");

            // run measurement system tangential
            isNormPolar = false;
            Console.Write("Zeroing AUT...");
            this.motor.GoHome();
            Console.WriteLine("\rAUT zeroed.");
            this.arduino.StartPendulum(Globals.TARGET_ANGLE);
            Console.WriteLine("Rotate the probe 90 deg. Make sure Probe is vertical.");
            Console.WriteLine("Push the pendulum arm. Press enter when done.");
            Console.ReadLine();
            Console.Write("Starting the E_tangent measurement. ");

            if (this.arduino.WaitTillPendulumReady())
            {
                Console.Write("Pendulum is ready. ");
                for (int i = 0; i < numOfPartial; i++)
                {
                    this.RunContinuousMeasurement_Partial(start_speed, speed, Globals.PARTIAL_MEAS_ANGLE, isNormPolar);
                }
            }
            this.arduino.EndPendulum();
            Console.WriteLine("\rFinished the E_tangent measurement.");
            system_watch.Stop();

        }

        /// <summary>
        ///  this will inc motor for a given distance, while the motor is runnig 
        /// it time stamp the feedback angle of the motor and add it to the MotorAng_MeasList
        /// this will return after motor motion ended
        /// </summary>
        /// <param name="start_speed"></param>
        /// <param name="speed"></param>
        /// <param name="distance"></param>
        private void RunContinuousMeasurement_Partial(double start_speed, double speed, double distance, bool isNormPolar)
        {
            this.isNormPolarList.Add(isNormPolar);
            Thread pna_thread = new Thread(new ThreadStart(this.threadRun_PNA));
            Thread arduino_thread = new Thread(new ThreadStart(this.threadRun_Arduino));
            List<Motor_MeasPoint> mmpl = new List<Motor_MeasPoint>();
            this.motor.IncMotorNonBlock(start_speed, speed, distance);
            this.motor_inMotion = true;

            //start the PNA Arduino Thread
            arduino_thread.Start();
            pna_thread.Start();

            while (!this.motor.IsMotionEnded()) // record angle and time while the motor is running
            {
                Motor_MeasPoint mmp;
                mmp.motorAng = this.motor.PositionFeedback();
                mmp.time = system_watch.Elapsed.TotalMilliseconds;
                mmpl.Add(mmp);
                Globals.MOTOR_CURRENT_ANGLE = mmp.motorAng;
            }
            this.MotorAng_MeasList.Add(mmpl);
            System.Threading.Thread.Sleep(800);
            this.motor_inMotion = false;
            pna_thread.Join(); // wait for pna thread to end
            arduino_thread.Join();
        }

        private void threadRun_PNA() 
        {
            this.pna_inMeas = true;
            List<PNA_MeasPoint> pmpl = new List<PNA_MeasPoint>();
            this.pna.configMeasurement(this.frequency, this.maxNumOfPoint,this.ifbw);
            int triggerCount = 0;
            while (this.motor_inMotion)
            {
                PNA_MeasPoint pmp;
                
                if (debug)
                {
                    this.penAngDebug.Add(this.arduino.GetInstanceAngle());
                }
                this.pna.manualTrigger(); // this timing is umpredictable
                pmp.time = system_watch.Elapsed.TotalMilliseconds;
                pmp.S21_imag = 0.0F; //dummy value
                pmp.S21_real = 0.0F; //dummy value
                pmpl.Add(pmp);
                triggerCount++;
                if (!debug)
                {
                    this.nop(Globals.TRIGGER_TIME_INTERVAL); // measurement time interval
                }
                
            }
            this.triggerCountList.Add(triggerCount);
            float[,] E_comp = this.pna.outputData(triggerCount);
            for(int i = 0; i < triggerCount; i++)
            {
                PNA_MeasPoint temp = pmpl[i];
                temp.S21_real = E_comp[i, 0];
                temp.S21_imag = E_comp[i, 1];
                pmpl[i] = temp;
            }
            this.pna_MeasList.Add(pmpl);
            this.pna_inMeas = false;

        }

        private void nop(double millisec)
        {
            this.nop_watch.Restart();
            while (this.nop_watch.Elapsed.TotalMilliseconds < millisec)
            {
                // no op
            }
            this.nop_watch.Stop();
        }

        private void threadRun_Arduino()
        {
            List<Arduino_MeasPoint> ampl = new List<Arduino_MeasPoint>();
            while (this.motor_inMotion||this.pna_inMeas)
            {
                Arduino_MeasPoint amp;
                amp.time = system_watch.Elapsed.TotalMilliseconds;
                amp.penAng = this.arduino.GetInstanceAngle();
                ampl.Add(amp);
            }
            this.penAng_MeasList.Add(ampl);
        }

        public void Test_threadRun_Arduino()
        {
            //initialize data stroage
            this.triggerCountList = new List<int>();
            this.pna_MeasList = new List<List<PNA_MeasPoint>>();
            this.motorAng_MeasList = new List<List<Motor_MeasPoint>>();
            this.penAng_MeasList = new List<List<Arduino_MeasPoint>>();
            this.isNormPolarList = new List<bool>();

            this.arduino.StartPendulum(Globals.TARGET_ANGLE);
            Console.WriteLine("Push the pendulum arm. Press enter when done.");
            Console.ReadLine();

            if (this.arduino.WaitTillPendulumReady())
            {
                system_watch.Restart();
                Thread arduino_thread = new Thread(new ThreadStart(this.threadRun_Arduino));
                this.motor_inMotion = true;

                //start the PNA Arduino Thread
                arduino_thread.Start();
                System.Threading.Thread.Sleep(10000);
                this.motor_inMotion = false;
                arduino_thread.Join();
                system_watch.Stop();
            }
            this.arduino.EndPendulum();
            List<Arduino_MeasPoint> ampl = this.penAng_MeasList[0];
            string filename = "Test_threadRun_Arduino.txt";
            for(int i = 0; i < ampl.Count; i++)
            {
                string line = ampl[i].time + ", " + ampl[i].penAng + "\n";
                File.AppendAllText(filename, line);
            }

        }

        public void Test_threadRun_PNA()
        {
            this.debug = true;
            //initialize data stroage
            this.triggerCountList = new List<int>();
            this.pna_MeasList = new List<List<PNA_MeasPoint>>();
            this.motorAng_MeasList = new List<List<Motor_MeasPoint>>();
            this.penAng_MeasList = new List<List<Arduino_MeasPoint>>();
            this.isNormPolarList = new List<bool>();
            this.penAngDebug = new List<double>();

            this.arduino.StartPendulum(Globals.TARGET_ANGLE);
            Console.WriteLine("Push the pendulum arm. Press enter when done.");
            Console.ReadLine();

            if (this.arduino.WaitTillPendulumReady())
            {
                system_watch.Restart();
                Thread pna_thread = new Thread(new ThreadStart(this.threadRun_PNA));
                this.motor_inMotion = true;

                //start the PNA Thread
                pna_thread.Start();
                System.Threading.Thread.Sleep(15000);
                this.motor_inMotion = false;
                pna_thread.Join();
                system_watch.Stop();
            }
            this.arduino.EndPendulum();

            List<PNA_MeasPoint> pmpl = this.pna_MeasList[0];
            string filename = "Test_threadRun_PNA.txt";
            for (int i = 0; i < pmpl.Count; i++)
            {
                string line = pmpl[i].time + ", " + this.penAngDebug[i] + "\n";
                File.AppendAllText(filename, line);
            }

            this.debug = false;

        }

    }
}
