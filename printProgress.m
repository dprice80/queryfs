function [] = printProgress(ii,tot,cr)
% ii = current iterations index
% tot = total number of iterations
% cr = carriage return {true|false} - useful for output in parfor loops

if nargin == 2
    cr = false;
end

if cr == false
    minres = round(tot/1000);
    
    if ii == 1 || ii == tot || tot < 1000 || round(rem(ii,minres)) == 0
        
        pc = ii/tot*100;
        
        if ii == 1
            fprintf(1,'\nComplete: ')
            fprintf(1,sprintf('%6.1f',pc))
            fprintf(1,'%%  ')
        else
            fprintf(1,'\b\b\b\b\b\b\b\b\b') % 9 backspaces
            fprintf(1,sprintf('%6.1f',pc)) % total length = 6, 1 decimal place
            fprintf(1,'%%  ') % 1 % sign and two space (9 characters in total) 
        end
        
        if ii == tot
            fprintf('\n') % at end of loop, add new line
        end
        
    end
    
else % instead of backspacing to clear line, insert carriage return.
    
    minres = round(tot/1000);
    
    if ii == 1 || ii == tot || round(rem(ii,minres)) == 0 || tot < 1000
        
        pc = ii/tot*100;
        
            fprintf(1,sprintf('%6.2f',pc))
            fprintf(1,'\n  ')
                
    end
end