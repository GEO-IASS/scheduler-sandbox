%% Create a flat radiance scene from a Gabor patch.
%
% This is a proof of concept.  I want to build up a "scene", which is a
% multi-spectral radiance image defined across a planar region.
%
% For this example, I'll assign objects to slots explicitly.  The slots
% will check if the objet I'm offering is a good match for the slot.
%
% 2016 isetbio team

clear
clc

%% Some entities.

% use Gabor patch to interpolate between two spectra
gabor = SsGaborPatch( ...
    'phase', 0, ...
    'stddev', 2, ...
    'frequency', 0.5, ...
    'orientation', pi()/12, ...
    'gain', 0.75);

% use 3-plane spectra so we can view them as rgb
spectralGabor = SsTwoSpectrumImage( ...
    'lowSpectrum', SsSpectrum(1:3, 'magnitudes', [1 0 0]), ...
    'highSpectrum', SsSpectrum(1:3, 'magnitudes', [0 0 1]));
spectralGabor.offer(gabor);

% plug the interpolated reflectance into a flat scene with pixels
scene = SsPlanarScene( ...
    'illuminant', SsSpectrum(1:3, 'magnitudes', [.5 .5 .5]), ...
    'width', 10, ...
    'height', 10, ...
    'horizontalOffset', -5, ...
    'verticalOffset', -5, ...
    'pixelWidth', 500, ...
    'pixelHeight', 500);
scene.offer(spectralGabor);

% how will we view the scene?
pov = SsPointOfView( ...
    'fieldOfView', pi()/6, ...
    'distance', 1);

%% A point of gaze computation and its output streams.
gazePicker = SsRandomGazePicker( ...
    'speed', 3, ...
    'targetChangeInteval', 1);
gazePatch = SsStream();
gazeTarget = SsStream();
gazeBox = SsStream();

gazePatch.input = gazePicker;
gazeTarget.input = gazePicker;
gazeBox.input = gazePicker;

gazePicker.offer(scene);
gazePicker.offer(pov);
gazePicker.offer(gazePatch, 'assignmentTarget', 'gazePatch');
gazePicker.offer(gazeTarget, 'assignmentTarget', 'gazeTarget');
gazePicker.offer(gazeBox, 'assignmentTarget', 'gazeBox');


%% Downstream computations for plotting.
gazePlotter = SsGazePlotter();
gazePlotter.offer(scene);
gazePlotter.offer(gazeTarget, 'assignmentTarget', 'gazeTarget');
gazePlotter.offer(gazeBox, 'assignmentTarget', 'gazeBox');

patchPlotter = SsPatchPlotter();
patchPlotter.offer(gazePatch, 'assignmentTarget', 'gazePatch');

%% Scheduler to wangle computation updates.
scheduler = SsTicTocScheduler();
scheduler.add(gazePicker);
scheduler.add(gazePlotter);
scheduler.add(patchPlotter);

%% Simulate some random gazes.
scheduler.initialize();
scheduler.run(5);

%% Make a plot of our "wiring".

% put all our objects in one container
context = SsSlotContext();
context.add(gabor);
context.add(spectralGabor);
context.add(scene);
context.add(pov);
context.add(gazePicker);
context.add(gazePatch);
context.add(gazeTarget);
context.add(gazeBox);
context.add(gazePlotter);
context.add(patchPlotter);
context.add(scheduler);

% let the container draw a diagram
ssPlotSlots(context);
