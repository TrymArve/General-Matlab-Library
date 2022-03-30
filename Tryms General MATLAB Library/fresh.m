function[] = fresh()
% cleans everything for a fresh start when running a script
evalin('base','clc')
evalin('base','clear all')
evalin('base','close all')
end