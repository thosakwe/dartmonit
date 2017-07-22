using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.ServiceProcess;
using System.Text;

namespace DartmonitWindowsService
{
    public partial class DartmonitService : ServiceBase
    {
        private String snapshotPath;

        public DartmonitService()
        {
            InitializeComponent();
            ServiceName = "dartmonit daemon";
            EventLog.Log = "Application";

            // Resolve snapshot location
            String appData = Environment.GetEnvironmentVariable("AppData");//Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            EventLog.WriteEntry($"App data: {appData}");
            String pubCache = Path.Combine(appData, "Pub\\Cache");
            EventLog.WriteEntry($"Pub cache: {pubCache}");
            snapshotPath = Path.Combine(pubCache, "global_packages\\dartmonit\\bin\\dartmon.dart.snapshot");
            EventLog.WriteEntry($"Snapshot: {snapshotPath}");
        }

        void LogProcess(Process p)
        {
            var stdout = p.StandardOutput.ReadToEnd();
            var stderr = p.StandardError.ReadToEnd();

            if (stdout.Length > 0)
                EventLog.WriteEntry(stdout, EventLogEntryType.Information);
            if (stderr.Length > 0)
                EventLog.WriteEntry(stderr, EventLogEntryType.Error);
        }

        protected override void OnStart(string[] args)
        {
            try
            {
                var dart = new ProcessStartInfo("dart", $"\"{snapshotPath}\" start")
                {
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };

                var p = Process.Start(dart);
                p.WaitForExit();
                LogProcess(p);
            }
            catch (Exception exc)
            {
                EventLog.WriteEntry($"Failed to start dartmonit: {exc.Message}", EventLogEntryType.Error);
                EventLog.WriteEntry(exc.StackTrace.ToString(), EventLogEntryType.Information);
            }
        }

        protected override void OnStop()
        {
            try
            {
                var dart = new ProcessStartInfo("dart", $"\"{snapshotPath}\" stop")
                {
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };

                var p = Process.Start(dart);
                p.WaitForExit();
                LogProcess(p);
            }
            catch (Exception exc)
            {
                EventLog.WriteEntry($"Failed to stop dartmonit: {exc.Message}", EventLogEntryType.Error);
                EventLog.WriteEntry(exc.StackTrace.ToString(), EventLogEntryType.Information);
            }
        }
    }
}
