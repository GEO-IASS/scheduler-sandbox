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
    'name', '', ...
    'color', []);

nOfferings = numel(inputData);
for oo = 1:nOfferings
    offering = inputData(oo).offering;
    
    % choose the node name
    if isprop(offering, 'name') && ~isempty(offering.name)
        inputData(oo).name = sprintf('%s %s', class(offering), offering.name);
    else
        inputData(oo).name = sprintf('%s %d', class(offering), oo);
    end
    
    % choose the node color
    if isa(offering, 'SsEntity')
        color = [.5 1 .5];
    elseif isa(offering, 'SsComputation')
        color = [.5 .5 1];
    elseif isa(offering, 'SsStream')
        color = [1 1 .0];
    else
        color = 0.5 * [1 1 1];
    end
    inputData(oo).color = color;
end


%% Create an object grapher to draw the graph.
grapher = SsDataGrapher();
grapher.inputData = inputData;
grapher.colors = cat(1, inputData.color);
grapher.listedEdgeNames = true;
grapher.floatingEdgeNames = false;
grapher.graphVisAlgorithm = 'dot';
grapher.edgeColorFromTarget = true;
grapher.edgeFunction = @edgesFromSlots;
grapher.graphIsDirected = true;
grapher.listedEdgeNames = true;

grapher.graphProperties.overlap= 'prism';
grapher.graphProperties.splines = false;
grapher.graphProperties.rankdir = 'LR';

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
edgeIndexes = zeros(1, nSlots);
edgeNames = cell(1, nSlots);
isEdge = false(1, nSlots);
for ss = 1:nSlots
    slot = slots(ss);
    if isempty(slot.assignmentTarget)
        continue;
    end
    
    if ~isprop(offering, slot.assignmentTarget)
        continue;
    end
    
    target = offering.(slot.assignmentTarget);
    targetIndex = slotContext.indexOf(target);
    if isempty(targetIndex)
        continue;
    end
    
    edgeIndexes(ss) = targetIndex;
    edgeNames{ss} = slot.assignmentTarget;
    isEdge(ss) = true;
end
edgeIndexes = edgeIndexes(isEdge);
edgeNames = edgeNames(isEdge);
