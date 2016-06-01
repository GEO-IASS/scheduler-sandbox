classdef SsSlotContext < handle
    % Hold simulation objects, wire them together.  Distribute them?
    
    properties
        offerings = {};
    end
    
    methods
        function index = add(obj, offering)
            nOfferings = numel(obj.offerings);
            for oo = 1:nOfferings
                % only add a given object once, by handle identity
                if obj.offerings{oo} == offering
                    index = oo;
                    return;
                end
            end
            index = nOfferings + 1;
            obj.offerings{index} = offering;
        end
        
        function plugInSlots(obj)
            % For each Slot of each SlotTarget, assign the best offering.
            %   time is nOfferings * nOfferings * mean-slots-per-offering
            nOfferings = numel(obj.offerings);
            for oo = 1:nOfferings
                
                % if this object is not a slot target, skip it
                target = obj.offerings{oo};
                if ~isa(target, 'SsSlotTarget')
                    continue;
                end
                
                % make offerings to each slot declared by this object
                slots = target.declareSlots();
                nSlots = numel(slots);
                for ss = 1:nSlots
                    slot = slots(ss);
                    
                    % sanity check to avoid work
                    if ~isprop(target, slot.assignmentTarget)
                        warning('SlotContext:noSuchTargetSlot', ...
                            'Slot Target has no property "%s".', slot.assignmentTarget);
                        continue;
                    end
                    
                    % let the slot score each offering
                    scores = zeros(1, nOfferings);
                    for ff = 1:nOfferings
                        offering = obj.offerings{ff};
                        [scores(ff), message] = slot.evaluateOffering(offering);
                    end
                    
                    % assign the best offering to the slot target
                    [bestScore, bestIndex] = max(scores);
                    if bestScore <= 0
                        warning('SlotContext:unmatchedSlot', message);
                        continue;
                    end
                    bestOffering = obj.offerings{bestIndex};
                    target.(slot.assignmentTarget) = bestOffering;
                end
            end
        end
    end
end
