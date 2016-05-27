%% Sanity check for the benefit of caching in SsFlatImage.
%
% SsFlatImage can cache computed images, as long as you pass in a 'tag'
% parameter to label the cached result.  This should speed things up when
% computing or loading large images.
%
% It would be possible to use the x-y sampling as the tag and cache things
% automatically.  But computing the hash for a large set of x-y values
% could take as much time as computing the image!  Using human-readable
% tags is easier and faster.
%
% 2016 isetbio team

clear
clc

%% Compute a Gabor patch at various sizes.
gabor = SsGaborPatch();
pix = [512 1024 2048 4096];
nPix = numel(pix);

%% Compute several reps with and without tagging.
nReps = 5;
rawTimes = zeros(nReps, nPix);
tagTimes = zeros(nReps, nPix);

for pp = 1:nPix
    x = linspace(-10, 10, pix(pp));
    y = x;
    tag = sprintf('%d', pix(pp));
    for rr = 1:nReps
        tic();
        rawPatch = gabor.sampleGrid(x, y, 'tag', tag);
        tagTimes(rr, pp) = toc();
        
        tic();
        tagPatch = gabor.sampleGrid(x, y);
        rawTimes(rr, pp) = toc();
    end
end

%% Contrast results in a plot.
% Dashed lines should be constant and large, for repeated, "raw"
% computatios.  Dotted lines should drop to small values after the first
% repetition, for "tagged" values that we look up.
names = cell(1, 2 * nPix);
colors = lines(nPix);
for pp = 1:nPix
    color = colors(pp, :);
    
    line(1:nReps, rawTimes(:, pp), ...
        'LineStyle', '--', ...
        'LineWidth', 3, ...
        'Color', color);
    names{2 * pp - 1} = sprintf('%d raw', pix(pp));
    
    line(1:nReps, tagTimes(:, pp), ...
        'LineStyle', ':', ...
        'LineWidth', 3, ...
        'Color', color);
    names{2 * pp} = sprintf('%d tagged', pix(pp));
end
legend(gca(), names{:}, 'Location', 'east');
set(gca(), 'XTick', 1:nReps);
