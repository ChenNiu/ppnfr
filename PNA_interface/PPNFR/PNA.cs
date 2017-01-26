using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using AgilentPNA835x;

namespace PPNFR
{
    class PNA
    {
        private string hostname;
        private AgilentPNA835x.Application app;
        private AgilentPNA835x.IChannel chan;
        private AgilentPNA835x.IMeasurement meas;
        private AgilentPNA835x.ITriggerSetup trigerSetup;
        private int numPoint; // num of measurement point in one channel
        private int triggerCount;

        public PNA(string hostname)
        {
            this.hostname = hostname;
            try
            {
                Type t = Type.GetTypeFromProgID("AgilentPNA835x.Application", hostname, true);
                this.app = (AgilentPNA835x.Application)Activator.CreateInstance(t);
                this.app.Reset();
            }
            catch (Exception e)
            {
                Console.WriteLine("An error occured: {0}", e.Message);
            }
        }

        public void configMeasurement(double freq, int numPoint)
        {
            this.numPoint = numPoint;
            this.app.Reset();
            this.app.CreateMeasurement(1, "S21", 1);
            this.chan = this.app.ActiveChannel;
            this.meas = this.app.ActiveMeasurement;
            this.trigerSetup = this.app.TriggerSetup;

            this.chan.Hold(true);

            this.app.TriggerSignal = AgilentPNA835x.NATriggerSignal.naTriggerManual;
            this.chan.TriggerMode = AgilentPNA835x.NATriggerMode.naTriggerModePoint;
            this.trigerSetup.Source = AgilentPNA835x.NATriggerSource.naTriggerSourceManual;
            this.trigerSetup.Scope = AgilentPNA835x.NATriggerType.naChannelTrigger;
            this.app.Visible = true;
            //this.chan.IFBandwidth = 600e3;

            this.chan.CWFrequency = freq;

            this.chan.SweepType = AgilentPNA835x.NASweepTypes.naCWTimeSweep;
            // for some reasom the first triggle is very slow, so do a dummy trigger first
            this.chan.NumberOfPoints = numPoint + 1;

            this.chan.Continuous();

            // dummy trigger
            this.app.ManualTrigger();

            this.triggerCount = 0;
        }

        public bool manualTrigger()
        {
            
            bool success = false;
            if (triggerCount < numPoint)
            {
                this.app.ManualTrigger();
                triggerCount++;
                success = true;
            }
            return success;
        }

        public float[,] outputData(int num)
        {
            if(num >= this.chan.NumberOfPoints)
            {
                throw new InvalidOperationException("Request num is bigger than chan.NumberOfPoints-1!");
            }
            System.Threading.Thread.Sleep(50); // wait for data is ready
            float[,] output = new float[num, 2];
            object[] dataArrayAsObj_real, dataArrayAsObj_imag;
            dataArrayAsObj_real = (object[])this.meas.getData(AgilentPNA835x.NADataStore.naMeasResult, AgilentPNA835x.NADataFormat.naDataFormat_Real);
            dataArrayAsObj_imag = (object[])this.meas.getData(AgilentPNA835x.NADataStore.naMeasResult, AgilentPNA835x.NADataFormat.naDataFormat_Imaginary);
            // ignore the first measurement since it is a dummy trigger
            for (int i = 0; i < num; i++)
            {
                output[i, 0] = (float)dataArrayAsObj_real[i + 1];
                output[i, 1] = (float)dataArrayAsObj_imag[i + 1];
            }
            return output;
        }
    }
}
