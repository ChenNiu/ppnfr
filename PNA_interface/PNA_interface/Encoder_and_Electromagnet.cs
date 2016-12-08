using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.IO.Ports;

namespace PNA_interface
{
    class Encoder_and_Electromagnet
    {
        SerialPort arduino_port;
        String arduino_program_version = "2.1.0";


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
            this.TurnOffEverything();
        }

        public bool Setup4ActiveEncoderOut(double target_angle, double delta_angle)
        {
            bool success = false;
            //Clear buffer
            string rem = arduino_port.ReadExisting();
            if (this.StartPendulum(target_angle))
            {
                Console.WriteLine("Push the pendulum arm. Press enter when done.");
                Console.ReadLine();
                if (this.WaitTillPendulumReady())
                {
                    if (this.StartEncoderOutActive(delta_angle))
                    {
                        success = true;
                    }
                }
            }
            return success;
        }

        public bool Setup4PassiveEncoderOut(double target_angle)
        {
            bool success = false;
            //Clear buffer
            string rem = arduino_port.ReadExisting();
            if (this.StartPendulum(target_angle))
            {
                Console.WriteLine("Push the pendulum arm. Press enter when done.");
                Console.ReadLine();
                if (this.WaitTillPendulumReady())
                {
                    if (this.StartEncoderOutPassive())
                    {
                        success = true;
                    }
                }
            }
            return success;

        }

        public bool TurnOffEverything()
        {
            bool success = false;
            //Clear buffer
            string rem = arduino_port.ReadExisting();
            if (this.EndEncoderOut())
            {
                if (this.EndPendulum())
                {
                    success = true;
                }
            }
            return success;
        }

        private void send(String cmd)
        {
            //if (Globals.LOGGING)
            //{
            //    DateTime now = DateTime.Now;
            //    File.AppendAllText(log_path, now.ToString("yyyy-MM-dd hh:mm:ss fff") + " Controller " + id + " - Sent: " + cmd + "\n");
            //}
            arduino_port.WriteLine(cmd);

        }

        // Blocking receive
        private string recv()
        {
            String response = "";
            // Gets bytes sent by controller
            // wait until there is a char response from the motor
            arduino_port.NewLine = "\n"; // change to the last character we expect
            arduino_port.ReadTimeout = 5000;
            try
            {
                response = arduino_port.ReadLine();
                response = response.Trim();
            }
            catch (TimeoutException e)
            {
                response = "-1";
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

        private bool successAction(string command, int tries, int delayMillisec)
        {
            bool success = false;
            while (!success && tries > 0)
            {
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

        public bool StartEncoderOutActive(double delta_angle)
        {
            int tries = 3;
            int delayMillisec = 100;
            string command;
            command = "2 " + delta_angle;
            return successAction(command, tries, delayMillisec);
        }

        public bool StartEncoderOutPassive()
        {
            int tries = 3;
            int delayMillisec = 100;
            string command;
            command = "3";
            return successAction(command, tries, delayMillisec);
        }

        public bool WaitTillPendulumReady()
        {
            // wait max 1min
            int tries = 120;
            int delayMillisec = 500;
            string command = "r"; //ready?
            return successAction(command, tries, delayMillisec);
        }

        public bool EndPendulum()
        {
            int tries = 3;
            int delayMillisec = 100;
            string command;
            command = "4";
            return successAction(command, tries, delayMillisec);
        }

        public bool EndEncoderOut()
        {
            int tries = 3;
            int delayMillisec = 100;
            string command;
            command = "5";
            return successAction(command, tries, delayMillisec);
        }

        public double GetInstanceAngle()
        {
            string command, resp;
            command = "i";
            this.send(command);
            resp = this.recv();
            return Double.Parse(resp);
        }
    } // end class
}// end namespace
