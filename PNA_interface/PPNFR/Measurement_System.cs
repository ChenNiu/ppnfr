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

        

        // flag
        bool motor_inMotion = false;

        // divices
        PNA pna;
        SCX11 motor;
        Encoder_and_Electromagnet arduino;

        // data storage
        List<int> triggerCountList;
        List<bool> isNormPolarList;
        List<List<Arduino_PNA_MeasPoint>> S21_MeasList;
        List<List<Motor_MeasPoint>> MotorAng_MeasList;

        // data storage getter
        public List<int> TriggerCountList { get { return this.triggerCountList; } }
        public List<bool> IsNormPolarList { get { return this.isNormPolarList; } }
        public List<List<Arduino_PNA_MeasPoint>> S21_MeasLists { get { return this.S21_MeasList; } }
        public List<List<Motor_MeasPoint>> MotorAng_MeasLists { get { return this.MotorAng_MeasList; } }

        // time stamp
        Stopwatch system_watch = new Stopwatch();

        // debug
        public bool print2Console = false;
         
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
            this.S21_MeasList = new List<List<Arduino_PNA_MeasPoint>>();
            this.MotorAng_MeasList = new List<List<Motor_MeasPoint>>();
            this.isNormPolarList = new List<bool>();


            // setup parameters
            double start_speed = 1.0;
            double speed = 10.0;

            this.motor.GoHome();
            this.arduino.StartPendulum(Globals.TARGET_ANGLE);
            Console.WriteLine("Push the pendulum arm. Press enter when done.");
            Console.ReadLine();
            if (this.arduino.WaitTillPendulumReady())
            {
                system_watch.Restart();
                this.RunContinuousMeasurement_Partial(start_speed, speed, 180, true);
                this.RunContinuousMeasurement_Partial(start_speed, speed, 181, true);
                system_watch.Stop();
            }
            this.arduino.EndPendulum();

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
            Thread pna_arduino_thread = new Thread(new ThreadStart(this.threadRun_PNA_Arduino));
            List<Motor_MeasPoint> mmplist = new List<Motor_MeasPoint>();
            this.motor.IncMotorNonBlock(start_speed, speed, distance);
            this.motor_inMotion = !this.motor.IsMotionEnded();

            //start the PNA Arduino Thread
            pna_arduino_thread.Start();

            while (this.motor_inMotion) // record angle and time while the motor is running
            {
                Motor_MeasPoint mmp;
                mmp.motorAng = this.motor.PositionFeedback();
                mmp.time = system_watch.Elapsed.TotalMilliseconds;
                mmplist.Add(mmp);
                this.motor_inMotion = !this.motor.IsMotionEnded();
            }
            this.MotorAng_MeasList.Add(mmplist);
            pna_arduino_thread.Join(); // wait for pna arduino thread to end
        }

        /// <summary>
        /// this thread will config a new PNA measurement 
        /// start the trigger and pen angle time stamp
        /// untill motor motion is ended
        /// retrive data from pna and added to the list
        /// </summary>
        private void threadRun_PNA_Arduino() 
        {
            List<Arduino_PNA_MeasPoint> apmplist = new List<Arduino_PNA_MeasPoint>();
            this.pna.configMeasurement(this.frequency, this.maxNumOfPoint);
            int triggerCount = 0;
            while (this.motor_inMotion)
            {
                Arduino_PNA_MeasPoint apmp;
                apmp.time = system_watch.Elapsed.TotalMilliseconds;
                this.pna.manualTrigger();
                apmp.penAng = this.arduino.GetInstanceAngle();
                apmp.S21_imag = 0.0F; //dummy value
                apmp.S21_real = 0.0F; //dummy value
                apmplist.Add(apmp);

                triggerCount++;
            }
            this.triggerCountList.Add(triggerCount);
            float[,] E_comp = this.pna.outputData(triggerCount);
            for(int i = 0; i < triggerCount; i++)
            {
                Arduino_PNA_MeasPoint temp = apmplist[i];
                temp.S21_real = E_comp[i, 0];
                temp.S21_imag = E_comp[i, 1];
                apmplist[i] = temp;
            }

            this.S21_MeasList.Add(apmplist);

        }


    }
}
