-- Pandoc filter: simplify the Huida Word manual into clean GitHub Markdown.
-- Unwraps block quotes, drops anchors/image sizes, flattens table cells so
-- pandoc can emit pipe tables instead of raw HTML.

function BlockQuote(el)
  return el.content
end

function Span(el)
  if el.classes:includes("anchor") or #el.content == 0 then
    return {}
  end
  return el.content
end

function Image(el)
  el.attributes = {}
  el.title = ""
  return el
end

function Figure(el)
  return el.content
end

local function flatten_cell(cell)
  local inl = pandoc.List()
  for i, blk in ipairs(cell.contents) do
    local s = pandoc.utils.blocks_to_inlines({blk})
    if #inl > 0 and #s > 0 then inl:insert(pandoc.Str("<br>")) end
    inl:extend(s)
  end
  -- remove soft/hard line breaks inside cells
  local out = pandoc.List()
  for _, x in ipairs(inl) do
    if x.t == "LineBreak" or x.t == "SoftBreak" then
      out:insert(pandoc.Space())
    else
      out:insert(x)
    end
  end
  cell.contents = { pandoc.Plain(out) }
  cell.row_span = 1
  cell.col_span = 1
  return cell
end

function Table(tbl)
  tbl.colspecs = tbl.colspecs:map(function(c) return {c[1], pandoc.ColWidthDefault} end)
  local function fix_rows(rows)
    for _, r in ipairs(rows) do
      for i, c in ipairs(r.cells) do r.cells[i] = flatten_cell(c) end
    end
  end
  fix_rows(tbl.head.rows)
  for _, b in ipairs(tbl.bodies) do
    fix_rows(b.head)
    fix_rows(b.body)
  end
  fix_rows(tbl.foot.rows)
  -- promote first body row to header if there is no header
  if #tbl.head.rows == 0 and #tbl.bodies > 0 and #tbl.bodies[1].body > 0 then
    tbl.head.rows = { table.remove(tbl.bodies[1].body, 1) }
  end
  return tbl
end
