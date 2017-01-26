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
    class Encoder_and_Electromagnet
    {
        SerialPort arduino_port;
        String arduino_program_version = "3.0.1";
        public bool print2Console = false; // debuging tool


        public Encoder_and_Electromagnet()
        {

        }
        public Encoder_and_Electromagnet(SerialPort arduino_port)
        {
            this.arduino_port = arduino_port;

            //Clear buffer
            string rem = arduino_port.ReadExisting();

            this.send("v"); //request for version
            string resp = recv();
            if (!resp.Equals(this.arduino_program_version)) {
                throw new InvalidOperationException("Not the right arduino program version");
            }
            this.EndPendulum();
        }

        //public bool Setup4ActiveEncoderOut(double target_angle, double delta_angle)
        //{
        //    bool success = false;
        //    //Clear buffer
        //    string rem = arduino_port.ReadExisting();
        //    if (this.StartPendulum(target_angle))
        //    {
        //        Console.WriteLine("Push the pendulum arm. Press enter when done.");
        //        Console.ReadLine();
        //        if (this.WaitTillPendulumReady())
        //        {
        //            if (this.StartEncoderOutActive(delta_angle))
        //            {
        //                success = true;
        //            }
        //        }
        //    }
        //    return success;
        //}

        //public bool Setup4PassiveEncoderOut(double target_angle)
        //{
        //    bool success = false;
        //    //Clear buffer
        //    string rem = arduino_port.ReadExisting();
        //    if (this.StartPendulum(target_angle))
        //    {
        //        Console.WriteLine("Push the pendulum arm. Press enter when done.");
        //        Console.ReadLine();
        //        if (this.WaitTillPendulumReady())
        //        {
        //            if (this.StartEncoderOutPassive())
        //            {
        //                success = true;
        //            }
        //        }
        //    }
        //    return success;

        //}

        //public bool TurnOffEverything()
        //{
        //    bool success = false;
        //    //Clear buffer
        //    string rem = arduino_port.ReadExisting();
        //    if (this.EndEncoderOut())
        //    {
        //        if (this.EndPendulum())
        //        {
        //            success = true;
        //        }
        //    }
        //    return success;
        //}

        private void send(String cmd)
        {
            //if (Globals.LOGGING)
            //{
            //    DateTime now = DateTime.Now;
            //    File.AppendAllText(log_path, now.ToString("yyyy-MM-dd hh:mm:ss fff") + " Controller " + id + " - Sent: " + cmd + "\n");
            //}
            arduino_port.WriteLine(cmd);
            if (this.print2Console)
            {
                Console.WriteLine(">" + cmd);
            }

        }

        // Blocking receive
        private string recv()
        {
            string response = "";
            // Gets bytes sent by controller
            // wait until there is a char response from the motor
            arduino_port.NewLine = "\n"; // change to the last character we expect
            arduino_port.ReadTimeout = 5000;
            try
            {
                response = arduino_port.ReadLine().Trim();
            }
            catch (TimeoutException e)
            {
                response = "-1";
            }

            if (this.print2Console)
            {
                Console.WriteLine(response);
            }

            return response;
        }

        private bool successMessage()
        {
            bool success = false;
            string resp = this.recv();
            if (resp.Equals("1"))
            {
                success = true;
            }
            return success;
        }

        private bool successRecvMessage(string message, int tries)
        {
            bool success = false;
            string resp;
            while (!success && tries > 0)
            {
                resp = this.recv();
                if (resp.Equals(message))
                {
                    success = true;
                }
                tries--;
            }
                
            return success;
        }

        private bool successAction(string command, int tries, int delayMillisec)
        {
            bool success = false;
            while (!success && tries > 0)
            {
                //Clear buffer
                string rem = arduino_port.ReadExisting();
                this.send(command);
                if (this.successMessage())
                {
                    success = true;
                }
                System.Threading.Thread.Sleep(delayMillisec);
                tries--;
            }
            return success;
        }

        public bool StartPendulum(double targetAngle)
        {
            int tries = 3;
            int delayMillisec = 100;
            string command;
            command = "1 " + targetAngle;
            return successAction(command, tries, delayMillisec);
        }

        //public bool StartEncoderOutActive(double delta_angle)
        //{
        //    int tries = 3;
        //    int delayMillisec = 100;
        //    string command;
        //    command = "2 " + delta_angle;
        //    return successAction(command, tries, delayMillisec);
        //}

        //public bool StartEncoderOutPassive()
        //{
        //    int tries = 3;
        //    int delayMillisec = 100;
        //    string command;
        //    command = "3";
        //    return successAction(command, tries, delayMillisec);
        //}

        public bool WaitTillPendulumReady()
        {
            // wait max 1min
            int tries = 120;
            int delayMillisec = 500;
            string command = "r"; //ready?
            return successAction(command, tries, delayMillisec);
        }

        //public bool WaitTillReturnStart()
        //{
        //    bool success = false;
        //    int tries = 3;
        //    int delayMillisec = 100;
        //    string ready = "r", status = "s";
        //    if(this.successAction(ready, tries, delayMillisec))
        //    {
        //        if(this.successAction(status, tries, delayMillisec))
        //        {
        //            if (this.successRecvMessage("start", 1000))
        //            {
        //                success = true;
        //            }
        //        }
        //    }
        //    return success;
        //}

        public bool EndPendulum()
        {
            int tries = 3;
            int delayMillisec = 100;
            string command;
            command = "4";
            return successAction(command, tries, delayMillisec);
        }

        //public bool EndEncoderOut()
        //{
        //    int tries = 3;
        //    int delayMillisec = 100;
        //    string command;
        //    command = "5";
        //    return successAction(command, tries, delayMillisec);
        //}

        public double GetInstanceAngle()
        {
            //Stopwatch pen_watch = new Stopwatch();
            string command, resp;
            command = "i";
            this.send(command);
            //Console.WriteLine("sent"+pen_watch.Elapsed.TotalMilliseconds);
            //pen_watch.Restart();
            resp = this.recv();
            //Console.WriteLine("recv"+pen_watch.Elapsed.TotalMilliseconds);
            double angle = Double.Parse(resp);
            if (Math.Abs(angle) > 90)
            {
                angle = angle / 10000;
            }
            return angle;
        }
    } // end class
}// end namespace
