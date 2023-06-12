using DataPicker, Test




@testset "Read SVG" begin
    # reads an SVG file and returns a NamedTuple with the various 3D curves
    fname="data/Alps.HZ.svg";
    Curves = parse_SVG(fname, verbose=false)

    @test length(Curves.S_Apennines) == 8
    @test sum(Curves.S_Apennines[1]) ≈ 12692.584694246085

    # Combines the curves to matrixes
    Surfaces = create_surfaces(Curves);
    @test  maximum(Surfaces.WZ[2]) ≈ 1484.7895734589033

    # Save to paraview
    @test isnothing(Write_Paraview(Surfaces))


end
