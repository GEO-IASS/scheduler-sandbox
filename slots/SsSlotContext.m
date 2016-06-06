classdef SsSlotContext < handle
    % Hold simulation objects, wire them together.  Distribute them?
    
    % TODO: factor out code for visiting objects that have slots?
    % TODO: compute big matrix of scores for all offerings and slots, once,
    % instead of repeating nested loops in various methods.
    
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
                return;
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
            % Do all autocreating before making any offerings,
            % that way order of offering won't matter.
            % If we autocreated lazily while making offerings,
            % an early offering might fail even though a suitable object
            % would have been autocreated later.
            obj.autocreateForSlots();
            obj.makeOfferingsToSlots();
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
                    
                    % don't create if a suitable object already exists
                    %   "Suitable" means required *and preferred*
                    %   properties are matched.
                    mayCreate = true;
                    suitableScore = 1 + numel(slot.preferredProperties);
                    for ff = 1:nOfferings
                        offering = obj.offerings{ff};
                        score = slot.evaluateOffering(offering);
                        if score >= suitableScore
                            % found a match already
                            mayCreate = false;
                            break;
                        end
                    end
                    
                    if ~mayCreate
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
                    isAssigned = target.assignProperty(slot.assignmentTarget, bestOffering);
                    
                    % best or all offerings to target method
                    if slot.isTakeAll
                        isInvoked = false;
                        for ff = find(scores > 0)
                            offering = obj.offerings{ff};
                            isInvoked = isInvoked | target.invokeMethod(slot.invocationTarget, offering);
                        end
                    else
                        isInvoked = target.invokeMethod(slot.invocationTarget, bestOffering);
                    end
                    
                    if ~isAssigned && ~isInvoked
                        warning('SlotContext:unusedSlot', ...
                            'Slot Target "%s" has no property "%s" or method "%s".', ...
                            class(target), slot.assignmentTarget, slot.invocationTarget);
                    end
                end
                
                % invoke the target's lifecycle callback
                target.afterSlotAssignments(slots);
            end
        end
    end
end
