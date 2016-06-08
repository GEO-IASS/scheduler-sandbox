classdef SsSlotTarget < handle
    % Declare required objects and which properties to receive them.
    
    methods (Abstract)
        % what properties does this object need and where to assign them?
        slots = declareSlots(obj);
    end
    
    methods
        % extra initialization after slot assignments?
        function afterSlotAssignments(obj, slots)
            % default is no-op, subclasses may override
        end
        
        % for one offering, find the best slot(s), if any
        function isAccepted = offer(obj, offering, varargin)
            parser = SsInputParser();
            parser.addRequired('offering');
            parser.addParameter('takeAll', false, @islogical);
            parser.addParameter('assignmentTarget', '', @ischar);
            parser.addParameter('invocationTarget', '', @ischar);
            parser.parseMagically('caller', offering, varargin{:});
            
            isAccepted = false;
            
            % evaluate each slot as a candidate to take the offering
            slots = obj.declareSlots();
            nSlots = numel(slots);
            if nSlots < 1
                warning('SlotTarget:noSlots', 'Slot Target declares no Slots.');
                return;
            end
            
            scores = zeros(1, nSlots);
            for ss = 1:nSlots
                slot = slots(ss);
                
                % slot must match given property name, if any
                if ~isempty(assignmentTarget) && ~strcmp(assignmentTarget, slot.assignmentTarget)
                    continue;
                end
                
                % slot must match given method name, if any
                if ~isempty(invocationTarget) && ~strcmp(invocationTarget, slot.invocationTarget)
                    continue;
                end
                
                % rate the offering
                [scores(ss), message] = slot.evaluateOffering(offering);
            end
            
            % choose the best slot(s) to take the offering
            [bestScore, bestIndex] = max(scores);
            if bestScore <= 0
                warning('SlotTarget:unmatchedOffering', 'Offering not plugged in: %s', message);
                return;
            end
            bestSlot = slots(bestIndex);
            
            isAccepted = false;
            if ~isempty(bestSlot.invocationTarget)
                if takeAll
                    % offering to all slots's methods
                    isAccepted = false;
                    for ss = find(scores > 0)
                        slot = slots(ss);
                        isAccepted = isAccepted | ...
                            obj.invokeMethod(slot.invocationTarget, offering, slot);
                    end
                else
                    % offering to best slot's method
                    isAccepted = obj.invokeMethod(bestSlot.invocationTarget, offering, bestSlot);
                end
                
            elseif ~isempty(bestSlot.assignmentTarget)
                % offering to best slot's property
                isAccepted = obj.assignProperty(bestSlot.assignmentTarget, offering);
            end
            
            if ~isAccepted
                warning('SlotTarget:unusedOffering', ...
                    'Slot Target "%s" has no property "%s" or method "%s".', ...
                    class(obj), bestSlot.assignmentTarget, bestSlot.invocationTarget);
            end
        end
        
        % assign an offering to a property
        function isAssigned = assignProperty(obj, propertyName, offering)
            if ~ischar(propertyName) || ~isprop(obj, propertyName)
                isAssigned = false;
                return;
            end
            
            % don't clobber previous assignment
            if ~isempty(obj.(propertyName))
                isAssigned = true;
                return;
            end
            
            % go ahead
            obj.(propertyName) = offering;
            isAssigned = true;
        end
        
        % pass an offering to a method
        function isInvoked = invokeMethod(obj, methodName, offering, slot)
            if ~ischar(methodName) || ~ismethod(obj, methodName)
                isInvoked = false;
                return;
            end
            
            if slot.passSlot
                feval(methodName, obj, offering, slot);
            else
                feval(methodName, obj, offering, slot.invocationArgs{:});
            end
            isInvoked = true;
        end
    end
end
