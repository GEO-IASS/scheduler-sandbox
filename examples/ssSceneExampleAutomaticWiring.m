%% Create a flat radiance scene from a Gabor patch.
%
% This is a proof of concept.  I want to build up a "scene", which is a
% multi-spectral radiance image defined across a planar region.
%
% For this example, let our "slot context" do all the wiring up of objects.
% This will work out because our objects have declared "slots" that give
% enough information to decide what should be plugged in.
%
% 2016 isetbio team

clear
clc

%% A context to hold our objects and will wire them up.
context = SsSlotContext();

%% Some entities.

% use Gabor patch to interpolate between two spectra
gabor = SsGaborPatch( ...
    'phase', 0, ...
    'stddev', 2, ...
    'frequency', 0.5, ...c
    'orientation', pi()/12, ...
    'gain', 0.75);
context.add(gabor);

% use 3-plane spectra so we can view them as rgb
spectralGabor = SsTwoSpectrumImage( ...
    'lowSpectrum', SsSpectrum(1:3, 'magnitudes', [1 0 0]), ...
    'highSpectrum', SsSpectrum(1:3, 'magnitudes', [0 0 1]));
context.add(spectralGabor);

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

% how to view the scene?
pov = SsPointOfView( ...
    'fieldOfView', pi()/6, ...
    'distance', 1);
context.add(pov);

%% A point of gaze computation and its streams.
gazePicker = SsRandomGazePicker( ...
    'speed', 3, ...
    'targetChangeInteval', 1);
context.add(gazePicker);

%% Downstream computations for plotting.
gazePlotter = SsGazePlotter();
context.add(gazePlotter);

%% Scheduler to wangle computation updates.
scheduler = SsTicTocScheduler();
context.add(scheduler);

%% Simulate some random gazes.
context.plugInSlots();
scheduler.run(5);

%% Do it again, but add a new plot.
context.add(SsPatchPlotter());
context.plugInSlots();
scheduler.run(5);

%% Take a look at what the auto-wiring did.
ssPlotSlots(context);
