function [hImage, grapher] = ssPlotSlots(slotContext)
% Scan the given slotContext and make a graph of object assignments.

parser = SsInputParser();
parser.addRequired('slotContext', @isobject);
parser.parseMagically('caller', slotContext);

hImage = [];
grapher = [];

%% Scan the slot context for objects/nodes and assignments/edges.
inputData = struct( ...
    'context', slotContext, ...
    'offering', slotContext.offerings, ...
    'label', '', ...
    'nodeName', '', ...
    'color', []);

nOfferings = numel(inputData);
for oo = 1:nOfferings
    offering = inputData(oo).offering;
    
    % unique node name
    inputData(oo).nodeName = sprintf('%s%d', class(offering), oo);
    
    % informative label
    if isprop(offering, 'name') && ~isempty(offering.name)
        inputData(oo).label = sprintf('%s %s', class(offering), offering.name);
    else
        inputData(oo).label = sprintf('%s', class(offering));
    end
    
    % choose the node color
    if isa(offering, 'SsEntity')
        color = [.7 .9 .7];
    elseif isa(offering, 'SsComputation')
        color = [.6 .6 .8];
    elseif isa(offering, 'SsStream')
        color = [.9 .9 .3];
    else
        color = 0.5 * [1 1 1];
    end
    inputData(oo).color = color;
end


%% Create an object grapher to draw the graph.
grapher = SsDataGrapher();
grapher.inputData = inputData;
grapher.listedEdgeNames = true;
grapher.floatingEdgeNames = false;
grapher.graphVisAlgorithm = 'dot';
grapher.edgeColorFromTarget = true;
grapher.edgeFunction = @edgesFromSlots;
grapher.graphIsDirected = true;

%grapher.nodeProperties.shape = 'box';
%grapher.nodeProperties.style = 'filled';

grapher.graphProperties.outputorder = 'edgesfirst';
grapher.graphProperties.overlap = 'prism';
grapher.graphProperties.splines = false;
grapher.graphProperties.rankdir = 'BT';

%% Draw the graph!
figure()
grapher.writeDotFile();
imageFile = grapher.generateGraph();
hImage = imshow(imageFile);


%% Create graph edges from assignAs slots.
function [edgeIndexes, edgeNames] = edgesFromSlots(inputData, index)
dataElement = inputData(index);
offering = dataElement.offering;
if ~isa(offering, 'SsSlotTarget')
    edgeIndexes = [];
    edgeNames = {};
    return;
end

slotContext = dataElement.context;
slots = offering.declareSlots();
nSlots = numel(slots);
edgeIndexes = [];
edgeNames = {};
for ss = 1:nSlots
    slot = slots(ss);
    if isempty(slot.assignmentTarget)
        continue;
    end
    
    if ~isprop(offering, slot.assignmentTarget)
        continue;
    end
    
    targets = offering.(slot.assignmentTarget);
    for tt = 1:numel(targets)
        if iscell(targets)
            target = targets{tt};
        else
            target = targets(tt);
        end
        targetIndex = slotContext.indexOf(target);
        if isempty(targetIndex)
            continue;
        end
        edgeIndexes(end + 1) = targetIndex; %#ok<AGROW>
        edgeNames{end + 1} = slot.assignmentTarget; %#ok<AGROW>
    end
end

% sort by target index to avoid edge crossings (I hope...)
[edgeIndexes, order] = sort(edgeIndexes);
edgeNames = edgeNames(order);

