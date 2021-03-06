#Demo 2: Reflection coefficients
#-------------------------------------------------------------------------------
using InspectDR
using Colors
import Graphics: width, height


#==Input
===============================================================================#

#Constants
#-------------------------------------------------------------------------------
black = RGB24(0, 0, 0)
white = RGB24(1, 1, 1)
red = RGB24(1, 0, 0)
green = RGB24(0, 1, 0)
blue = RGB24(0, 0, 1)
μ0 = 4pi*1e-7 #F/m
ϵ0 = 8.854e-12 #H/m


#Input data
#-------------------------------------------------------------------------------
fmax = 10e9
fstep = 50e6
f = collect(0:fstep:fmax)
ℓ = 50e-3 #Meters
ZL = Float64[1e6, 377, 60.0]
_colors = [blue, red, green]


#==Equations
===============================================================================#
Γ(Z; Zref::Real=50.0) = (Z - Zref) ./ (Z + Zref)
#ZC: Characteristic impedance
#ZL: Load impendance (termination)
function Zline(ℓ::Real, f::Vector, ZL::Number; ZC::Number=50.0, α::Real=0, μ::Real=μ0, ϵ::Real=ϵ0)
	j = im
	β = f*(2pi*sqrt(μ*ϵ))
	γ = α+j*β
	tanh_γℓ = tanh(γ*ℓ)
	return ZC*(ZL+ZC*tanh_γℓ)./(ZC+ZL*tanh_γℓ)
end
function Γline(ℓ::Real, f::Vector, ZL::Number; ZC::Number=50.0, Zref::Number=50.0, α::Real=0, μ::Real=μ0, ϵ::Real=ϵ0)
	return Γ(Zline(ℓ, f, ZL; ZC=ZC, α=α, μ=μ, ϵ=ϵ), Zref=Zref)
end

#Calculations
#-------------------------------------------------------------------------------
Γload = []
for ZLi in ZL
	_Γ = Γline(ℓ, f, ZLi, ZC=40)
	push!(Γload, _Γ)
end


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Transmission Line Example")
mplot.ncolumns = 2

plot_linf = InspectDR.Plot2D()
	plot_linf.axes = InspectDR.axes(:lin, :dB20)
	plot_linf.ext_full = InspectDR.PExtents2D(ymax=5)
#	plot_linf.layout.legend.enabled=true
plot_logf = InspectDR.Plot2D()
	plot_logf.axes = InspectDR.axes(:log10, :dB20)
	plot_logf.ext_full = InspectDR.PExtents2D(xmin=10e6,ymax=5)
	plot_logf.layout.grid = grid(vmajor=true, vminor=true, hmajor=true)
plot_ysmith = InspectDR.Plot2D()
	plot_ysmith.axes = InspectDR.axes(:smith, :Y)
	plot_ysmith.ext_full = InspectDR.PExtents2D(xmin=-1.2,xmax=1.2,ymin=-1.2,ymax=1.2)
	plot_ysmith.layout.legend.enabled=true
plot_smith = InspectDR.Plot2D()
	plot_smith.axes = InspectDR.axes(:smith, :Z, ref=50)
	plot_smith.ext_full = InspectDR.PExtents2D(xmin=-1.2,xmax=1.2,ymin=-1.2,ymax=1.2)
	plot_smith.layout.legend.enabled=true

for plot in [plot_linf, plot_logf]
	a = plot.annotation
	a.title = "Reflection Coefficient (Γ)"
	a.xlabel = "Frequency (Hz)"
	a.ylabel = "Magnitude (dB)"
end

a = plot_ysmith.annotation
	a.title = "Y-Smith Chart"
	a.xlabel = "Real(Γ)"
	a.ylabel = "Imaginary(Γ)"

a = plot_smith.annotation
	a.title = "Z-Smith Chart"
	a.xlabel = "Real(Γ)"
	a.ylabel = "Imaginary(Γ)"

#Select which plots to actually display:
plotlist = [plot_linf, plot_logf, plot_ysmith, plot_smith]
#plotlist = [plot_smith]

for plot in plotlist
	for i in 1:length(Γload)
		wfrm = add(plot, f, Γload[i], id="ZL=$(ZL[i])")
		wfrm.line = line(color=_colors[i], width=2)
	end

	add(mplot, plot)
end

gplot = display(InspectDR.GtkDisplay(), mplot)


#==Save multi-plot to file
===============================================================================#

maximize_square = true
if maximize_square
	#Target plot size to get square Smith plots without gaps:
	lyt = plot_smith.layout
		lyt.wdata = 500
		lyt.hdata = 500
	bb = InspectDR.plotbounds(lyt, plot_smith.axes) #Required
		mplot.wplot = width(bb)
		mplot.hplot = height(bb)
end

InspectDR.write_png("export_multiplot.png", mplot)
InspectDR.write_svg("export_multiplot.svg", mplot)
InspectDR.write_eps("export_multiplot.eps", mplot)
InspectDR.write_pdf("export_multiplot.pdf", mplot)

:DONE
