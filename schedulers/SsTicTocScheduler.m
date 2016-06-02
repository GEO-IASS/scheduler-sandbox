classdef SsTicTocScheduler < SsScheduler
    % Updates in single file, with simulation time <--> clock time.
    
    methods
        function run(obj, until)
            obj.nextTimes = zeros(1, numel(obj.computations));
            obj.previousTimes = zeros(1, numel(obj.computations));
            
            tic();
            currentTime = 0;
            while currentTime < until
                % look up the next one
                [currentTime, currentIndex] = min(obj.nextTimes);
                computation  = obj.computations{currentIndex};
                
                % wait wall time approx the same as the simulation time
                delay = currentTime - toc();
                pause(delay);
                
                % update it the current computation
                obj.nextTimes(currentIndex) = computation.update(currentTime, obj.previousTimes(currentIndex));
                obj.previousTimes(currentIndex) = currentTime;
            end
        end
    end
end
