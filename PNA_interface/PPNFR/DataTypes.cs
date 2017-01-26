using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PPNFR
{
    // System state enumeration
    public enum State
    {
        // Configuration States
        Unconfigured = 1,
        Connected,
        Calculated,
        Configured,

        // Operation States
        Zeroing,
        Zeroed,
        Running,
        Ran,

        // Results States
        PostProcessing,
        DisplayingResults
    };

    public struct Arduino_PNA_MeasPoint
    {
        public double time; // in millisecs using stopwatch
        public double penAng;
        public float S21_real;
        public float S21_imag;
    }

    public struct Motor_MeasPoint
    {
        public double time;
        public double motorAng;
    }

    public struct System_MeasPoint
    {
        public double penAng;
        public double motorAng;
        public double x;
        public double y;
        public float S21_real;
        public float S21_imag;
        public bool isNormPolar;
    }

    public static class Globals
    {
        public static String SERIAL_LOG_FILE = "serial.log";
        public static bool LOGGING = false;
        public static string FILENAME = "testing.txt";

        // constants
        public static double C = 299792458; // m/s

        // System state
        public static State SYS_STATE;

        // System characteristic constants
        public static double ARM_LENGTH = 0.924; // m (from center of pen shaft to probe)

        // Measurement charateristic constants
        public static double FREQUENCY = 10e9; //default frequency;
        public static double TRUNCATION_ANGLE = 60.0;
        public static double TARGET_ANGLE = 20.0; //deg pendulum swing target angle

        // Motor characteristic constans
        public static double START_SPEED = 1.0; // VR
        public static double SPEED = 1.0; // VS

        // PNA characeristic constans
        public static int MAX_NUM_OF_POINTS = 32000;
    }
}