classdef SsSlotContext < handle
    % Hold simulation objects, wire them together.  Distribute them?
    
    % TODO: factor out code for visiting objects that have slots?
    
    properties
        offerings = {};
    end
    
    methods
        function index = add(obj, offering)
            nOfferings = numel(obj.offerings);
            index = obj.indexOf(offering);
            if isempty(index)
                % only add if this is a new offering
                index = nOfferings + 1;
                obj.offerings{index} = offering;
            end
        end
        
        function index = indexOf(obj, offering)
            index = [];
            if isempty(offering)
                returnl
            end
            
            nOfferings = numel(obj.offerings);
            for oo = 1:nOfferings
                % compare by handle identity, not value
                if obj.offerings{oo} == offering
                    index = oo;
                    return;
                end
            end
        end
        
        function plugInSlots(obj)
            obj.autocreateForSlots;
            obj.makeOfferingsToSlots;
        end
    end
    
    methods (Access = protected)
        
        function autocreateForSlots(obj)
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
                    if ~slot.isAutocreate
                        continue;
                    end
                    
                    offering = createOfferingForSlot(obj, slot);
                    obj.add(offering);
                end
            end
        end
        
        function offering = createOfferingForSlot(obj, slot)
            offering = [];
            
            if 2 ~= exist(slot.requiredClass, 'file')
                warning('SlotContext:noSuchClass', ...
                    'No such class "%s", cannot create object.', slot.requiredClass);
                return;
            end
            
            try
                constructor = str2func(slot.requiredClass);
                offering = feval(constructor);
            catch err
                warning('SlotContext:constructorError', ...
                    'Could not construct class "%s": ', slot.requiredClass, err.message);
                return;
            end
            
            obj.assignSlotPropertiesToOffering(slot.requiredProperties, offering);
            obj.assignSlotPropertiesToOffering(slot.preferredProperties, offering);
        end
        
        function assignSlotPropertiesToOffering(obj, propertyInfo, offering)
            nProperties = numel(propertyInfo);
            for pp = 1:nProperties
                propertyName = propertyInfo(pp).name;
                propertyValue = propertyInfo(pp).value;
                
                if ~isprop(offering, propertyName)
                    % no such property to assign
                    continue;
                end
                
                if isempty(propertyValue)
                    % no value to assign
                    continue;
                end
                
                % OK to assign
                offering.(propertyName) = propertyValue;
            end
        end
        
        function makeOfferingsToSlots(obj)
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
                    
                    % let the slot score each offering
                    scores = zeros(1, nOfferings);
                    for ff = 1:nOfferings
                        offering = obj.offerings{ff};
                        [scores(ff), message] = slot.evaluateOffering(offering);
                    end
                    
                    % assign the best offering to the slot target
                    [bestScore, bestIndex] = max(scores);
                    if bestScore <= 0
                        warning('SlotContext:unmatchedSlot', 'Slot not plugged in: %s', message);
                        continue;
                    end
                    bestOffering = obj.offerings{bestIndex};
                    
                    % best offering to target property
                    isAssigned = obj.assignTargetProperty(target, slot.assignmentTarget, bestOffering);
                    
                    % best or all offerings to target method
                    if slot.isTakeAll
                        isPassed = false;
                        for ff = find(scores > 0)
                            offering = obj.offerings{ff};
                            isPassed = isPassed | obj.invokeTargetMethod(target, slot.invocationTarget, offering);
                        end
                    else
                        isPassed = obj.invokeTargetMethod(target, slot.invocationTarget, bestOffering);
                    end
                    
                    if ~isAssigned && ~isPassed
                        warning('SlotContext:unusedSlot', ...
                            'Slot Target "%s" has no property "%s" or method "%s".', ...
                            class(target), slot.assignmentTarget, slot.invocationTarget);
                    end
                end
                
                % invoke the target's lifecycle callback
                target.afterSlotAssignments(slots);
            end
        end
        
        function isAssigned = assignTargetProperty(obj, target, propertyName, offering)
            if ~ischar(propertyName) || ~isprop(target, propertyName)
                isAssigned = false;
                return;
            end
            
            % don't clobber pervious assignment
            if ~isempty(target.(propertyName))
                isAssigned = true;
                return;
            end
            
            % go ahead
            target.(propertyName) = offering;
            isAssigned = true;
        end
        
        function isPassed = invokeTargetMethod(obj, target, methodName, offering)
            if ~ischar(methodName) || ~ismethod(target, methodName)
                isPassed = false;
                return;
            end
            
            % go ahead
            feval(methodName, target, offering);
            isPassed = true;
        end
    end
end
