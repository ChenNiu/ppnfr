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
        List<List<Arduino_PNA_MeasPoint>> S21_MeasList;
        List<List<Motor_MeasPoint>> MotorAng_MeasList;

        List<System_MeasPoint> processed_MeasList;
        public List<System_MeasPoint> Processed_Measurement_List { get { return processed_MeasList; } }

        public Data_Processor(List<bool> isNormPolarList, List<List<Arduino_PNA_MeasPoint>> S21_MeasList, List<List<Motor_MeasPoint>> MotorAng_MeasList)
        {
            this.isNormPolarList = isNormPolarList;
            this.S21_MeasList = S21_MeasList;
            this.MotorAng_MeasList = MotorAng_MeasList;
            this.processMeasuredData();
        }

        private double motorAng_linearInterp(List<Motor_MeasPoint> list, Arduino_PNA_MeasPoint point)
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

        private void processMeasuredData()
        {
            this.processed_MeasList = new List<System_MeasPoint>();
            for(int i = 0; i < this.S21_MeasList.Count; i++)
            {
                List<Arduino_PNA_MeasPoint> apmpl = this.S21_MeasList[i];
                List<Motor_MeasPoint> mmpl = this.MotorAng_MeasList[i];
                bool isNormPolar = this.isNormPolarList[i];

                for(int j = 0; j < apmpl.Count; j++)
                {
                    Arduino_PNA_MeasPoint apmp = apmpl[j];
                    if (Math.Abs(apmp.penAng) <= Globals.TARGET_ANGLE)
                    {
                        System_MeasPoint smp = this.kinematics(mmpl, apmp, isNormPolar);
                        this.processed_MeasList.Add(smp);
                    }
                }
            }

        }

        private System_MeasPoint kinematics(List<Motor_MeasPoint> list, Arduino_PNA_MeasPoint point, bool isNormPolar)
        {
            System_MeasPoint smp;
            double x, y;
            smp.penAng = point.penAng;
            smp.motorAng = this.motorAng_linearInterp(list, point);
            smp.S21_real = point.S21_real;
            smp.S21_imag = point.S21_imag;
            double penAng = point.penAng * Math.PI / 180;
            double motorAng = smp.motorAng * Math.PI / 180;
            // normal pendulum coordinate 
            x = Math.Sin(penAng) * Globals.ARM_LENGTH;
            y = -Math.Cos(penAng) * Globals.ARM_LENGTH;
            // pendulum highest point at (0,0)
            x = x + Math.Sin(Globals.TARGET_ANGLE * Math.PI / 180) * Globals.ARM_LENGTH;
            y = y + Math.Cos(Globals.TARGET_ANGLE * Math.PI / 180) * Globals.ARM_LENGTH;
            // coor rotation
            smp.x = Math.Cos(motorAng) * x - Math.Sin(motorAng) * y;
            smp.y = Math.Sin(motorAng) * x - Math.Cos(motorAng) * y;

            smp.isNormPolar = isNormPolar;

            return smp;
        }
        public void Print2File()
        {
            for(int i = 0; i < this.processed_MeasList.Count; i++)
            {
                System_MeasPoint smp = this.processed_MeasList[i];
                string line = smp.x + ", " + smp.y + ", " + smp.penAng + ", " + smp.motorAng + ", " + smp.S21_real + ", " + smp.S21_imag + ", " + smp.isNormPolar + "\n";
                File.AppendAllText(Globals.FILENAME, line);
            }
        }
    }
}
