function y=Report_Timing_Results(M,a,b,str)
persistent Results
if isempty(Results)
    Results={};
end
Results(M).name=str;
Results(M).elapsed_time=b;
Results(M).acceleration=a/b;
disp('----------------------------------------------------------------------------------------------');
disp('Versions of the WLAN Transceiver                     | Elapsed Time (sec)| Acceleration Ratio');
for m=1:M
fprintf(1,'%2d. %-49s| %17.4f | %12.4f\n',m, Results(m).name, Results(m).elapsed_time, Results(m).acceleration);
end
disp('----------------------------------------------------------------------------------------------');
y=Results;
end