using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PPNFR
{
    class Data_Processor
    {
        // data storage
        List<bool> isNormPolarList;
        List<List<PNA_MeasPoint>> pna_MeasList;
        List<List<Arduino_MeasPoint>> penAng_MeasList;
        List<List<Motor_MeasPoint>> motorAng_MeasList;

        List<System_MeasPoint> processed_MeasList;
        public List<System_MeasPoint> Processed_Measurement_List { get { return processed_MeasList; } }

        public Data_Processor(List<bool> isNormPolarList, List<List<PNA_MeasPoint>> pna_MeasList, List<List<Arduino_MeasPoint>> penAng_MeasList, List<List<Motor_MeasPoint>> motorAng_MeasList)
        {
            this.isNormPolarList = isNormPolarList;
            this.pna_MeasList = pna_MeasList;
            this.penAng_MeasList = penAng_MeasList;
            this.motorAng_MeasList = motorAng_MeasList;
            this.processMeasuredData();
        }

        private double motorAng_linearInterp(List<Motor_MeasPoint> list, PNA_MeasPoint point)
        {
            double motorAng = -1.0;
            // find left index
            int li = 0;
            int ri = 1;
            while(list[li].time < point.time && li < list.Count-1)
            {
                li++;
            }
            if(li > 0 && li < list.Count-1) // point is not inside the list
            {
                ri = li + 1;
                double k = (list[ri].motorAng - list[li].motorAng) / (list[ri].time - list[li].time);
                motorAng = list[li].motorAng + k * (point.time - list[li].time);
            }
            else
            {
                motorAng = list[list.Count - 1].motorAng;
            }
            return motorAng;
        }

        private double penAng_linearInterp(List<Arduino_MeasPoint> list, PNA_MeasPoint point)
        {
            double penAng = 180;
            // find left index
            int li = 0;
            int ri = 1;
            while (list[li].time < point.time && li < list.Count - 1)
            {
                li++;
            }
            if (li > 0 && li < list.Count - 1) // point is not inside the list
            {
                ri = li + 1;
                double k = (list[ri].penAng - list[li].penAng) / (list[ri].time - list[li].time);
                penAng = list[li].penAng + k * (point.time - list[li].time);
            }
            return penAng;
        }

        private void processMeasuredData()
        {
            this.processed_MeasList = new List<System_MeasPoint>();
            for(int i = 0; i < this.pna_MeasList.Count; i++)
            {
                List<PNA_MeasPoint> pmpl = this.pna_MeasList[i];
                List<Arduino_MeasPoint> ampl = this.penAng_MeasList[i];
                List<Motor_MeasPoint> mmpl = this.motorAng_MeasList[i];
                bool isNormPolar = this.isNormPolarList[i];

                for(int j = 0; j < pmpl.Count; j++)
                {
                    PNA_MeasPoint pmp = pmpl[j];
                    System_MeasPoint smp = this.kinematics(mmpl, ampl, pmp, isNormPolar);
                    if (Math.Abs(smp.penAng) <= Globals.TARGET_ANGLE)
                    {
                        this.processed_MeasList.Add(smp);
                    }
                }
            }

        }

        private System_MeasPoint kinematics(List<Motor_MeasPoint> mmpl, List<Arduino_MeasPoint> ampl, PNA_MeasPoint pmp, bool isNormPolar)
        {
            System_MeasPoint smp;
            smp.time = pmp.time;
            double x, y;
            smp.penAng = this.penAng_linearInterp(ampl, pmp);
            smp.motorAng = this.motorAng_linearInterp(mmpl, pmp);
            smp.S21_real = pmp.S21_real;
            smp.S21_imag = pmp.S21_imag;
            double penAng = smp.penAng * Math.PI / 180;
            double motorAng = smp.motorAng * Math.PI / 180;
            // normal pendulum coordinate 
            x = Math.Sin(-penAng) * Globals.ARM_LENGTH;
            y = -Math.Cos(-penAng) * Globals.ARM_LENGTH;
            // pendulum highest point at (0,0)
            x = x + Math.Sin(Globals.TARGET_ANGLE * Math.PI / 180) * Globals.ARM_LENGTH;
            y = y + Math.Cos(Globals.TARGET_ANGLE * Math.PI / 180) * Globals.ARM_LENGTH;
            // coor rotation
            smp.x = Math.Cos(motorAng) * x - Math.Sin(motorAng) * y;
            smp.y = Math.Sin(motorAng) * x + Math.Cos(motorAng) * y;

            smp.isNormPolar = isNormPolar;

            if (smp.isNormPolar)
            {
                smp.phaseAng = smp.motorAng - smp.penAng + 90;
            }
            else
            {
                smp.phaseAng = smp.motorAng - smp.penAng;
            }

            return smp;
        }
        public void Print2File()
        {
            string line = "Frequency = " + Globals.FREQUENCY/1e9 + "GHz, IFBW = " + Globals.IFBW/1e3 + "kHz, Z_distance = " + Globals.Z_DISTANCE + "m\n";
            line += "AUT dimension [m]: " + Globals.AUT_DIM_X + ", " + Globals.AUT_DIM_Y + ", " + Globals.AUT_DIM_Z + "\n";
            File.AppendAllText(Globals.FILENAME, line);
            for (int i = 0; i < this.processed_MeasList.Count; i++)
            {
                System_MeasPoint smp = this.processed_MeasList[i];
                line = smp.time + ", " + smp.x + ", " + smp.y + ", " + smp.penAng + ", " + smp.motorAng + ", " + smp.phaseAng + ", " + smp.S21_real + ", " + smp.S21_imag + ", " + Convert.ToInt32(smp.isNormPolar) + "\n";
                File.AppendAllText(Globals.FILENAME, line);
            }
        }
    }
}
