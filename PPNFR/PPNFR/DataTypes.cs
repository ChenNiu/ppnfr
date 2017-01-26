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

    public struct Arduino_MeasPoint
    {
        public double time; // in millisecs using stopwatch
        public double penAng;
    }

    public struct PNA_MeasPoint
    {
        public double time;
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
        public double time;
        public double penAng;
        public double motorAng;
        public double x;
        public double y;
        public float S21_real;
        public float S21_imag;
        public bool isNormPolar;
        public double phaseAng;
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
        public static double MOTOR_CURRENT_ANGLE = 0.0;

        // System characteristic constants
        public static double ARM_LENGTH = 0.924; // m (from center of pen shaft to probe)
        public static double Z_DISTANCE = 0.17; //m (from measurement plane to aut)

        // Measurement charateristic constants
        public static double FREQUENCY = 10e9; //default frequency;
        public static double IFBW = 10e3;
        public static double TRUNCATION_ANGLE = 60.0;
        public static double TARGET_ANGLE = 20.0; //deg pendulum swing target angle
        public static int TRIGGER_TIME_INTERVAL = 3; //ms

        // AUT chararteristic constants
        public static double AUT_DIM_X = 0.138; //m
        public static double AUT_DIM_Y = 0.178; //m
        public static double AUT_DIM_Z = 0.165; //m

        // Motor characteristic constans
        public static double START_SPEED = 1.0; // VR
        public static double SPEED = 1.0; // VS
        public static double PARTIAL_MEAS_ANGLE = 10.0 * SPEED; 

        // PNA characeristic constans
        public static int MAX_NUM_OF_POINTS = 3000;
        
    }
}