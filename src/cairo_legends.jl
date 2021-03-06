#InspectDR: Draw legends with Cairo layer.
#-------------------------------------------------------------------------------


#==
===============================================================================#

#NOTE: linelength & linegap are absolute values
function legend_renderitem(ctx::CairoContext, wfrm::DWaveform, x::Float64, y::Float64,
	linelength::Float64, linegap::Float64)
	linestart = x+linegap
	lineend = linestart+linelength

	Cairo.set_source(ctx, wfrm.line.color)
	setlinestyle(ctx, wfrm.line.style, Float64(wfrm.line.width))
	drawline(ctx, Point2D(linestart, y), Point2D(lineend, y))
	drawglyph_safe(ctx, wfrm, Point2D(linestart+linelength/2, y))
	x = lineend+linegap #Compute new x
	Cairo.set_source(ctx, COLOR_BLACK)
	render(ctx, wfrm.id, Point2D(x, y), align=ALIGN_VCENTER|ALIGN_LEFT)
end

function legend_render(canvas::PCanvas2D, plot::Plot2D)
	const ctx = canvas.ctx
	const lstyle = plot.layout.legend

	Cairo.save(canvas.ctx)
	setfont(ctx, lstyle.font)
	(w, h) = text_dims(Cairo.text_extents(ctx, "M"))
	ypitch = h*(1+lstyle.vgap)

	#Compute absolute values:
	linegap = lstyle.linegap*w

	x = canvas.bb.xmax - _width(lstyle)
	y = canvas.graphbb.ymin + h/2

	for d in plot.display_data
		if "" == d.id; continue; end
		legend_renderitem(ctx, d, x, y, lstyle.linelength, linegap)
		y += ypitch
	end
	Cairo.restore(canvas.ctx)
end


#Last line
