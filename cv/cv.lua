-- Quarto/Pandoc filter for the CV PDF.
-- Converts semantic cv-entry / cv-pub / cv-header blocks into polished LaTeX.

local function latex_of(blocks)
  local doc = pandoc.Pandoc(blocks)
  local s = pandoc.write(doc, 'latex')
  s = s:gsub('%s+$', '')
  return s
end

function Div(el)
  if not FORMAT:match('latex') then
    return nil
  end

  if el.classes:includes('cv-entry') then
    local date = el.attributes['date'] or ''
    local body = latex_of(el.content)
    return pandoc.RawBlock('latex',
      '\\cvrowstart{' .. date .. '}\n' .. body .. '\n\\cvrowend')
  end

  if el.classes:includes('cv-pub') then
    local body = latex_of(el.content)
    return pandoc.RawBlock('latex',
      '\\begin{cvpub}\n' .. body .. '\n\\end{cvpub}')
  end

  if el.classes:includes('cv-header') then
    -- Extract the first Header as the name and the rest as contact information.
    local name = 'Seolmin YANG'
    local rest = {}
    for _, b in ipairs(el.content) do
      if b.t == 'Header' and b.level == 1 then
        name = pandoc.utils.stringify(b.content)
      else
        table.insert(rest, b)
      end
    end
    local contact = latex_of(rest)
    return pandoc.RawBlock('latex',
      '\\cvname{' .. name .. '}\n\\cvcontact{' .. contact .. '}')
  end
end


-- The H1 is consumed by cv-header and should not become a document section.
function Header(el)
  if FORMAT:match('latex') and el.level == 1 then
    return {}
  end
end
