using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Ports;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PNA_interface
{
    /// <summary>
    /// this is a class for the oriental motor controller SCX11
    /// this object abstruct all communication to the motor controller. 
    /// </summary>
    class SCX11
    {
        SerialPort controller_port;

        // constructor

        public SCX11(SerialPort controller_port)
        {
            this.controller_port = controller_port;
            // initialize controller for controlling DG60 motor and ARD-K driver
            // Set default
            string UU = "=deg"; // user unit
            string DPR = "=360"; // distance per revolution
            string MR = "=500"; //motor resolution
            string GA = "=18";
            string GB = "=1"; //gear radio 10:1 for DG60 motor
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

            // config GA
            commond = "GA" + GA;
            send(commond);
            resp = recv(">");

            // config GB
            commond = "GB" + GB;
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

        public void IncMotor(double start_speed, double speed, double distance)
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
            IncMotor(20, 20, 3.00);
        }

        private void wait_2_MotionEnd()
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

            return response;
        }
    }
}
