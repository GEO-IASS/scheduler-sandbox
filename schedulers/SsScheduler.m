classdef SsScheduler < SsSlotTarget
    % Wrangle updates for multiple computations.
    
    properties
        nextTimes;
        previousTimes;
        
        % slotted
        computations = {};
    end
    
    methods (Abstract)
        run(obj, until);
    end
    
    methods
        function slots = declareSlots(obj)
            slots(1) = SsSlot() ...
                .passTo('add') ...
                .requireClass('SsComputation') ...
                .takeAll(true);
        end
        
        function afterSlotAssignments(obj, slots)
            obj.initialize();
        end
        
        function initialize(obj)
            % init timestamp bookkeeping
            obj.nextTimes = zeros(1, numel(obj.computations));
            obj.previousTimes = zeros(1, numel(obj.computations));
        end
        
        function initializeComputations(obj)
            nComputations = numel(obj.computations);
            for oo = 1:nComputations
                obj.computations{oo}.initialize();
            end
        end
        
        function index = add(obj, computation)
            nComputations = numel(obj.computations);
            for oo = 1:nComputations
                % only add a given object once, by handle identity
                if obj.computations{oo} == computation
                    index = oo;
                    return;
                end
            end
            index = nComputations + 1;
            obj.computations{index} = computation;
        end
    end
end