% Demo for generating a graph using SsDataGrapher.
%
% This allows us to lay out arbitrary graph data with with the Graphviz
% tool.
%

clear;
clc;

%% Create the grapher object.
dg = SsDataGrapher();
dg.listedEdgeNames = true;
dg.floatingEdgeNames = true;

%% Make some arbitrary data in the form of node names and numbered edges.
data(1).name = 'a or A';
data(1).edge = 2;
data(2).name = 'b';
data(2).edge = 3;
data(3).name = 'c';
data(3).edge = [1 2];
dg.inputData = data;

%% Generate a graph of the arbitrary data.
dg.writeDotFile();
imageFile = dg.generateGraph();
imshow(imageFile);
