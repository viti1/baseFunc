function results = convert_du2W(l,eff, G)
    h=6.62*10^-34;
    c = 3e8;
    g = db2pow(G) * 255 / 10.5e3 ;
    results=h*c/(l*g*eff);
end