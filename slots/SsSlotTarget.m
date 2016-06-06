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
        
        % check an offering, maybe assign or pass to method
        function isAccepted = offer(obj, offering, varargin)
            parser = SsInputParser();
            parser.addRequired('offering');
            parser.addParameter('firstOnly', true, @islogical);
            parser.addParameter('assignmentTarget', '', @ischar);
            parser.addParameter('invocationTarget', '', @ischar);
            parser.parseMagically('caller', offering, varargin{:});
            
            isAccepted = false;
            
            % try to assign at each slot
            slots = obj.declareSlots();
            nSlots = numel(slots);
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
                score = slot.evaluateOffering(offering);
                if score <= 0
                    continue;
                end
                
                % try to take the offering
                isAssigned = obj.assignProperty(slot.assignmentTarget, offering);
                isInvoked = obj.invokeMethod(slot.invocationTarget, offering);
                isAccepted = isAssigned || isInvoked;
                
                % stop after the first accepted offering?
                if isAccepted && firstOnly
                    return;
                end
            end
        end
        
        % assign an offering to a property
        function isAssigned = assignProperty(obj, propertyName, offering)
            if ~ischar(propertyName) || ~isprop(obj, propertyName)
                isAssigned = false;
                return;
            end
            
            % don't clobber pervious assignment
            if ~isempty(obj.(propertyName))
                isAssigned = true;
                return;
            end
            
            % go ahead
            obj.(propertyName) = offering;
            isAssigned = true;
        end
        
        % pass an offering to a method
        function isInvoked = invokeMethod(obj, methodName, offering)
            if ~ischar(methodName) || ~ismethod(obj, methodName)
                isInvoked = false;
                return;
            end
            
            % go ahead
            feval(methodName, obj, offering);
            isInvoked = true;
        end
    end
end
