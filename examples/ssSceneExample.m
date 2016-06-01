%% Create a flat radiance scene from a Gabor patch.
%
% This is a proof of concept.  I want to build up a "scene", which is a
% multi-spectral radiance image defined across a planar region.
%
% TODO: move distance and fov params to separate Entity
% TODO: should be able to create output streams automatically
% TODO: update timeInfo with defaults
%
% 2016 isetbio team

clear
clc

%% A context to hold our objects and will wire them up.
context = SsSlotContext();


%% Some entities.

% use Gabor patch to interpolate between two spectra.
gabor = SsGaborPatch( ...
    'phase', 0, ...
    'stddev', 2, ...
    'frequency', 0.5, ...
    'orientation', pi()/12, ...
    'gain', 0.75);
context.add(gabor);

% use 3-plane spectra so we can view them as rgb
interpolated = SsTwoSpectrumImage( ...
    'lowSpectrum', SsSpectrum(1:3, 'magnitudes', [1 0 0]), ...
    'highSpectrum', SsSpectrum(1:3, 'magnitudes', [0 0 1]));
context.add(interpolated);

% plug the interpolated reflectance into a flat scene.
scene = SsPlanarScene( ...
    'illuminant', SsSpectrum(1:3, 'magnitudes', [.5 .5 .5]), ...
    'width', 10, ...
    'height', 10, ...
    'horizontalOffset', -5, ...
    'verticalOffset', -5, ...
    'pixelWidth', 500, ...
    'pixelHeight', 500);
context.add(scene);


%% A computation and its streams.
gazePicker = SsRandomGazePicker( ...
    'fieldOfView', pi()/6, ...
    'speed', 3);
context.add(gazePicker);
context.add(SsStream('name', 'gazePatch'));
context.add(SsStream('name', 'gazeTarget'));
context.add(SsStream('name', 'gazeBox'));


%% Let the context wire up our objects automatically.
context.plugInSlots();


%% Set up some plots before running the simulation.
radiance = scene.sampleWholeScene();

subplot(2, 1, 1);
imshow(radiance, [0 1]);
title('scene');
hold on
targetLine = line(0, 0, ...
    'Marker', '+', ...
    'MarkerSize', 10, ...
    'Color', [0 1 0]);
boxLine = line(0, 0, ...
    'LineStyle', '-', ...
    'LineWidth', 2, ...
    'Color', [0 1 0]);
hold off


%% Simulate some random gazes.

% for viewing purposes, make simulation time <--> wall time
duration = 5;
tic();
previousTime = 0;
currentTime = 0;

gazePlot = subplot(2, 1, 2);
while currentTime < duration
    % let the computation update itself
    nextTime = gazePicker.update(currentTime, previousTime);
    
    % where are we looking?
    target = gazePicker.gazeTarget.currentValue();
    [targetX, targetY] = scene.sceneToPixels(target(1), target(2));
    set(targetLine, ...
        'XData', targetX, ...
        'YData', targetY);
    box = gazePicker.gazeBox.currentValue();
    [boxX, boxY] = scene.sceneToPixels(box(1:2), box(3:4));
    set(boxLine, ...
        'XData', boxX([1 1 2 2 1]), ...
        'YData', boxY([1 2 2 1 1]));
    
    % what are we looking at?
    patch = gazePicker.gazePatch.currentValue();
    imshow(patch, [0 1]);
    title(gazePlot, 'gaze');
    
    % wait wall time approx the same as the simulation time
    pause(nextTime - currentTime);
    previousTime = currentTime;
    currentTime = nextTime;
end
