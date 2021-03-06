#InspectDR: IO functionnality for writing plots with Cairo
#-------------------------------------------------------------------------------

#==Constants
===============================================================================#
typealias MIMEpng MIME"image/png"
typealias MIMEsvg MIME"image/svg+xml"
typealias MIMEeps MIME"image/eps"
typealias MIMEpdf MIME"application/pdf"

const MAPEXT2MIME = Dict{AbstractString,MIME}(
	".png" => MIMEpng(),
	".svg" => MIMEsvg(),
	".eps" => MIMEeps(),
	".pdf" => MIMEpdf(),
)

#If an easy way to read Cairo scripts back to a surface is found:
#typealias MIMEcairo MIME"image/cairo"

#All supported MIMEs:
#EXCLUDE SVG so it can be turnd on/off??
typealias MIMEall Union{MIMEpng, MIMEeps, MIMEpdf, MIMEsvg}


#=="Constructors"
===============================================================================#
_CairoSurface(io::IO, ::MIMEsvg, w::Float64, h::Float64) =
	Cairo.CairoSVGSurface(io, w, h)
_CairoSurface(io::IO, ::MIMEeps, w::Float64, h::Float64) =
	Cairo.CairoEPSSurface(io, w, h)
_CairoSurface(io::IO, ::MIMEpdf, w::Float64, h::Float64) =
	Cairo.CairoPDFSurface(io, w, h)


#=="withsurf" interface: Make uniform API for all output surfaces
===============================================================================#
function withsurf(fn::Function, stream::IO, mime::MIME, w::Float64, h::Float64)
	surf = _CairoSurface(stream, mime, w, h)
	ctx = CairoContext(surf)
	fn(ctx)
	Cairo.destroy(ctx)
	Cairo.destroy(surf)
end

#There is no PNG stream surface... must write from ARGB surface.
function withsurf(fn::Function, stream::IO, mime::MIMEpng, w::Float64, h::Float64)
	w = round(w); h = round(h)
	surf = Cairo.CairoARGBSurface(w, h)
	ctx = CairoContext(surf)
	fn(ctx)
	Cairo.destroy(ctx)
	Cairo.write_to_png(surf, stream)
	Cairo.destroy(surf)
end


#=="writemime" interface
===============================================================================#

#Maintain text/plain MIME support (Is this ok?).
Base.writemime(io::IO, ::MIME"text/plain", plot::Plot) = Base.showlimited(io, plot)
Base.writemime(io::IO, ::MIME"text/plain", mplot::Multiplot) = Base.showlimited(io, mplot)


#w, h: w/h of a SINGLE plot.
function _writemime(stream::IO, mime::MIME, mplot::Multiplot, w::Float64, h::Float64)
	nplots = length(mplot.subplots)
	ncols = mplot.ncolumns
	nrows = div(nplots-1, ncols) + 1
	yoffset = mplot.htitle
	wtot = w*ncols; htot = h*nrows+yoffset

	withsurf(stream, mime, wtot, htot) do ctx
		render(ctx, mplot.title, Point2D(wtot/2, yoffset/2),
			mplot.fnttitle, align=ALIGN_HCENTER|ALIGN_VCENTER
		)

		for i in 1:nplots
			row = div(i-1, ncols) + 1
			col = i - (row-1)*ncols
			xmin = (col-1)*w; ymin = yoffset+(row-1)*h
			bb = BoundingBox(xmin, xmin+w, ymin, ymin+h)
			Cairo.save(ctx) #-----
			setclip(ctx, bb) #Avoid accidental overwrites.
			render(ctx, mplot.subplots[i], bb)
			Cairo.restore(ctx) #-----
		end
	end
end

#_writemime() Plot: Leverage write to Multiplot
function _writemime(stream::IO, mime::MIME, plot::Plot, w::Float64, h::Float64)
	mplot = Multiplot()
	mplot.htitle = 0
	push!(mplot.subplots, plot)
	_writemime(stream, mime, mplot, w, h)
end

#_writemime() Plot2D: Auto-coumpute w/h
function _writemime(stream::IO, mime::MIME, plot::Plot2D)
	bb = plotbounds(plot.layout, plot.axes)
	_writemime(stream, mime, plot, bb.xmax, bb.ymax)
end

#Default writemime behaviour: MethodError
Base.writemime(io::IO, mime::MIME, mplot::Multiplot) =
	throw(MethodError(writemime, (io, mime, mplot)))
Base.writemime(io::IO, mime::MIME, plot::Plot) =
	throw(MethodError(writemime, (io, mime, plot)))

#writemime() Plot/Multiplot: Supported MIMEs:
Base.writemime(io::IO, mime::MIMEall, mplot::Multiplot) =
	_writemime(io, mime, mplot, mplot.wplot, mplot.hplot)
Base.writemime(io::IO, mime::MIMEall, plot::Plot) =
	_writemime(io, mime, plot)


#=="mimewritable" interface
===============================================================================#
Base.mimewritable(mime::MIME"text/plain", mplot::Multiplot) = true
Base.mimewritable(mime::MIME, mplot::Multiplot) = false #Default
Base.mimewritable(mime::MIMEall, mplot::Multiplot) = true #Supported
Base.mimewritable(mime::MIMEsvg, mplot::Multiplot) = defaults.rendersvg #depends

Base.mimewritable(mime::MIME"text/plain", p::Plot) = true
Base.mimewritable(mime::MIME, p::Plot) = Base.mimewritable(mime::MIME, Multiplot())


#=="write" interface
===============================================================================#

#_write() Multiplot:
function _write(path::AbstractString, mime::MIME, mplot::Multiplot, w::Float64, h::Float64)
	io = open(path, "w")
	_writemime(io, mime, mplot, w, h)
	close(io)
end

#_write() Plot: Leverage write to Multiplot
function _write(path::AbstractString, mime::MIME, plot::Plot, w::Float64, h::Float64)
	mplot = Multiplot()
	mplot.htitle = 0
	push!(mplot.subplots, plot)
	_write(path, mime, mplot, w, h)
end

#_write() Multiplot: Auto-coumpute w/h
_write(path::AbstractString, mime::MIME, mplot::Multiplot) =
	_write(path, mime, mplot, mplot.wplot, mplot.hplot)

#_write() Plot2D: Auto-coumpute w/h
function _write(path::AbstractString, mime::MIME, plot::Plot2D)
	bb = plotbounds(plot.layout, plot.axes)
	_write(path, mime, plot, bb.xmax, bb.ymax)
end


#==Non-MIME write interface (convenience functions)
===============================================================================#

write_png(path::AbstractString, mplot::Multiplot) = _write(path, MIMEpng(), mplot)
write_svg(path::AbstractString, mplot::Multiplot) = _write(path, MIMEsvg(), mplot)
write_eps(path::AbstractString, mplot::Multiplot) = _write(path, MIMEeps(), mplot)
write_pdf(path::AbstractString, mplot::Multiplot) = _write(path, MIMEpdf(), mplot)

write_png(path::AbstractString, plot::Plot) = _write(path, MIMEpng(), plot)
write_svg(path::AbstractString, plot::Plot) = _write(path, MIMEsvg(), plot)
write_eps(path::AbstractString, plot::Plot) = _write(path, MIMEeps(), plot)
write_pdf(path::AbstractString, plot::Plot) = _write(path, MIMEpdf(), plot)

#Last line
