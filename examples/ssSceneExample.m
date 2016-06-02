%% Create a flat radiance scene from a Gabor patch.
%
% This is a proof of concept.  I want to build up a "scene", which is a
% multi-spectral radiance image defined across a planar region.
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

patchPlotter = SsPatchPlotter();
context.add(patchPlotter);


%% Scheduler to wangle computation updates.
scheduler = SsTicTocScheduler();
context.add(scheduler);


%% Let the context wire up our objects automatically.
context.plugInSlots();


%% Simulate some random gazes.
scheduler.run(5);
