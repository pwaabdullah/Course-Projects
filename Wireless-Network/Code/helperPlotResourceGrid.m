function helperPlotResourceGrid(colors,Level)

% If no aggregation level specified, use 1
if (nargin == 1)
    Level = 1;
end

% If need to aggregate by 6 or 12
if Level > 1
    % Filter function by blocks of 6.
    H = size(colors,1);
    W = size(colors,2);
    Coarse = zeros(H/Level, W);
    
    % filter: keep the color that has the most hits in the 6x1 group
    for col = 1:W
        for row = 1:H/Level
            dist = histc(colors((row-1)*Level+(1:Level),col),1:10);
            [~,ind] = max(dist);
            Coarse(row,col) = ind;
        end
    end
    
    % Use filtered colors.
    colors = Coarse;
end
grid = ones(size(colors));

% Determine number of subcarriers 'K' and number of OFDM symbols 'L'
% in input resource grid
K = size(grid,1);
L = size(grid,2);

% Pad edges of resource grid and colors
grid = [zeros(K,1) grid zeros(K,2)];
grid = [zeros(1,L+3); grid; zeros(2,L+3)];
colors = [zeros(K,1) colors zeros(K,2)];
colors = [zeros(1,L+3); colors; zeros(1,L+3)];
for k = 1:K+3
    for l = L+3:-1:2
        if (grid(k,l)==0 && grid(k,l-1)~=0)
            grid(k,l) = grid(k,l-1);
        end
    end
end
for l = 1:L+3
    for k = K+3:-1:2
        if (grid(k,l)==0 && grid(k-1,l)~=0)
            grid(k,l) = grid(k-1,l);
        end
    end
end

% Create resource grid power matrix, with a floor of -40dB
powers = 20*log10(grid+1e-2);

% Create surface plot of powers
h = surf((-1:L+1)-0.5,(-1:K+1)-0.5,powers,colors);

% Create and apply color map
ColorArray = ListColors();
NrColors = size(ColorArray,1);
caxis([0 NrColors-1]);
colormap(ColorArray);
set(h,'EdgeColor',[0.25 0.25 0.25]);

% Set view and axis ranges
axis([-1.5 L+0.5 -1.5 K+0.5 min(powers(:))-5 max(powers(:))+5]);
view([0 90]);

% Set plot axis labels
zlabel('Power (dB)');
ylabel('Subcarrier index');
xlabel('OFDM symbol index');

end
