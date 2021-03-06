#InspectDR: Secondary annotation (Cairo layer)
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#
const ALIGN_MAP = Dict{Symbol, CAlignment}(
	:tl => ALIGN_TOP | ALIGN_LEFT,
	:tc => ALIGN_TOP | ALIGN_HCENTER,
	:tr => ALIGN_TOP | ALIGN_RIGHT,

	:cl => ALIGN_VCENTER | ALIGN_LEFT,
	:cc => ALIGN_VCENTER | ALIGN_HCENTER,
	:cr => ALIGN_VCENTER | ALIGN_RIGHT,

	:bl => ALIGN_BOTTOM | ALIGN_LEFT,
	:bc => ALIGN_BOTTOM | ALIGN_HCENTER,
	:br => ALIGN_BOTTOM | ALIGN_RIGHT,
)


#==Rendering text annotation
===============================================================================#
function render(canvas::PCanvas2D, a::TextAnnotation, axes::Axes)
	const ctx = canvas.ctx
	const graphbb = canvas.graphbb
	align = get(ALIGN_MAP, a.align, ALIGN_BOTTOM | ALIGN_LEFT)
	angle = deg2rad(a.angle)

	Cairo.set_source(ctx, a.color)
	pt = _rescale(a.pt, axes)
	pt = ptmap(canvas.xf, pt)
	x = pt.x; y = pt.y
	if isnan(x); x = graphbb.xmin; end
	if isnan(y); y = graphbb.ymax; end
	x += a.xoffset * width(graphbb)
	y -= a.yoffset * height(graphbb)
	render(ctx, a.text, Point2D(x,y), a.font, angle=angle, align=align)
	return
end

render(canvas::PCanvas2D, alist::Vector{TextAnnotation}, axes::Axes) =
	map((a)->render(canvas, a, axes::Axes), alist)


#==Rendering markers
===============================================================================#

function render(canvas::PCanvas2D, mkr::HVMarker, axes::Axes)
	const ctx = canvas.ctx
	const graphbb = canvas.graphbb
	if :none == mkr.line.style
		return
	end

	Cairo.set_source(ctx, mkr.line.color)
	setlinestyle(ctx, mkr.line.style, Float64(mkr.line.width))
	pt = _rescale(Point2D(mkr.pos, mkr.pos), axes)
	pt = ptmap(canvas.xf, pt)

	if mkr.vmarker
		drawline(ctx, Point2D(pt.x, graphbb.ymin), Point2D(pt.x, graphbb.ymax))
	else #hmarker
		drawline(ctx, Point2D(graphbb.xmin, pt.y), Point2D(graphbb.xmax, pt.y))
	end

	return
end

render(canvas::PCanvas2D, mkrlist::Vector{HVMarker}, axes::Axes) =
	map((mkr)->render(canvas, mkr, axes::Axes), mkrlist)

#Last line
