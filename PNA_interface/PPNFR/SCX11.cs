using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Ports;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PPNFR
{
    /// <summary>
    /// this is a class for the oriental motor controller SCX11
    /// this object abstruct all communication to the motor controller. 
    /// </summary>
    class SCX11
    {
        SerialPort controller_port;
        public bool print2Console = false; // debuging tool

        // constructor
        public SCX11()
        {
        }

        public SCX11(SerialPort controller_port)
        {
            this.controller_port = controller_port;
            // initialize controller for controlling DG60 motor and ARD-K driver
            // Set default
            string UU = "=deg"; // user unit
            string DPR = "=360"; // distance per revolution
            string MR = "=10000"; //motor resolution
            string ER = "=10000"; //encoder resolution
            string GA = "=18";
            string GB = "=1"; //gear radio 10:1 for DG60 motor
            string ENC = "=1"; // On driver connector for encoder
            // Set default for mechinical home sensing
            string INHOME = "=1"; // set I/O pin for home sensor
            string HOMETYP = "=4";

            string commond, resp;

            // config UU
            commond = "UU" + UU;
            send(commond);
            resp = recv(">");

            // config DPR
            commond = "DPR" + DPR;
            send(commond);
            resp = recv(">");

            // config MR
            commond = "MR" + MR;
            send(commond);
            resp = recv(">");

            // config ER
            commond = "ER" + ER;
            send(commond);
            resp = recv(">");

            // config GA
            commond = "GA" + GA;
            send(commond);
            resp = recv(">");

            // config GB
            commond = "GB" + GB;
            send(commond);
            resp = recv(">");

            // config ENC
            commond = "ENC" + ENC;
            send(commond);
            resp = recv(">");

            // config IHOME
            commond = "INHOME" + INHOME;
            send(commond);
            resp = recv(">");

            // conjig HOMETYP
            commond = "HOMETYP" + HOMETYP;
            send(commond);
            resp = recv(">");

            // save 
            send("SAVEPRM");
            send("Y");
            resp = recv(">");

            // reset 
            send("RESET");
            resp = recv(">");

        }

        public void IncMotorBlock(double start_speed, double speed, double distance)
        {
            string resp;
            string VS = "VS=" + start_speed;
            string VR = "VR=" + speed;
            string DIS = "DIS=" + distance;

            send(VS);
            resp = recv(">");
            send(VR);
            resp = recv(">");
            send(DIS);
            resp = recv(">");
            send("MI");
            resp = recv(">");
            wait_2_MotionEnd();
        }

        private void resetSystem()
        {
            // reset 
            send("RESET");
            recv(">");
        }

        private void resetEncoderCount()
        {
            send("EC=0");
            recv(">");
        }

        public void IncMotorNonBlock(double start_speed, double speed, double distance)
        {
            string resp;
            string VS = "VS=" + start_speed;
            string VR = "VR=" + speed;
            string DIS = "DIS=" + distance;

            send(VS);
            resp = recv(">");
            send(VR);
            resp = recv(">");
            send(DIS);
            resp = recv(">");
            send("MI");
            resp = recv(">");
        }

        // this is a bloking function, it will not return until motor reaches home. 
        public void GoHome()
        {
            string resp;
            string VS = "VS=20";
            string VR = "VR=20";

            send(VS);
            resp = recv(">");
            send(VR);
            resp = recv(">");
            send("MGHP");
            resp = recv(">");
            wait_2_MotionEnd();
            System.Threading.Thread.Sleep(2000);
            this.IncMotorBlock(1, 20, 3.00);
            //System.Threading.Thread.Sleep(100);
            this.resetEncoderCount();
        }

        public bool IsMotionEnded()
        {
            bool end = false;
            this.send("SIGEND"); // is motion ended?
            string resp = this.recv(">");
            if (resp.IndexOf("1") > 0)
            {
                end = true; // motion ended.
            }
            return end;
        }

        public double PositionFeedback()
        {
            double pf = 0.0;
            this.send("PF");
            string resp = this.recv(">").Trim();
            char[] delimiterChars = { ' ', '=' };
            string[] words = resp.Split(delimiterChars);
            pf = Convert.ToDouble(words[words.Length - 2]);
            return pf;
        }

        public void wait_2_MotionEnd()
        {
            bool end = false;
            string resp;
            while (!end)
            {
                send("SIGEND"); // is motion ended?
                resp = recv(">");
                if (resp.IndexOf("1") > 0)
                {
                    end = true;
                }
                //Console.WriteLine("running...");
            }
            //Console.WriteLine("Done.");
        }

        private void send(String cmd)
        {
            //if (Globals.LOGGING)
            //{
            //    DateTime now = DateTime.Now;
            //    File.AppendAllText(log_path, now.ToString("yyyy-MM-dd hh:mm:ss fff") + " Controller " + id + " - Sent: " + cmd + "\n");
            //}
            controller_port.WriteLine(cmd);
            if (this.print2Console)
            {
                Console.WriteLine(">" + cmd);
            }
        }

        // Blocking receive
        private String recv(string end_char)
        {
            string response = "";
            // Gets bytes sent by controller
            // wait until there is a char response from the motor
            controller_port.NewLine = end_char; // change to the last character we expect

            try
            {
                response = controller_port.ReadLine();
            }
            catch (TimeoutException e)
            {
                // probably a timeout
                response = controller_port.ReadExisting();
            }
            controller_port.NewLine = "\r"; // change endline character back

            //if (Globals.LOGGING)
            //{
            //    DateTime now = DateTime.Now;
            //    File.AppendAllText(log_path, now.ToString("yyyy-MM-dd hh:mm:ss fff") + " Controller " + id + " - Recv: " + response + "\n");
            //}

            if (this.print2Console)
            {
                Console.WriteLine(response);
            }

            return response;
        }
    }
}
