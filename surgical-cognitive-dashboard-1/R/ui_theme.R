#' UI Theme - Typography and Spacing System
#'
#' @description
#' Implements a professional typography system with bslib theming.
#' Uses 8px baseline grid for vertical rhythm and consistent spacing.
#'
#' @details
#' Based on Material Design and WCAG 2.1 AA accessibility standards.

# ============================================================================
# BSLIB THEME CONFIGURATION
# ============================================================================

#' Create Custom bslib Theme
#'
#' @return bslib theme object
#' @export
create_dashboard_theme <- function() {
  bslib::bs_theme(
    version = 5,
    
    # Base typography
    base_font = bslib::font_google("Inter"),
    heading_font = bslib::font_google("Inter", wght = c(600, 700)),
    code_font = bslib::font_google("Fira Code"),
    
    # Font sizes (use rem for consistency)
    "font-size-base" = "1rem",     # 16px default
    "font-size-sm" = "0.875rem",   # 14px
    "font-size-lg" = "1.125rem",   # 18px
    
    # Heading sizes (clear hierarchy)
    "h1-font-size" = "2.5rem",    # 40px - Page titles
    "h2-font-size" = "2rem",      # 32px - Section titles
    "h3-font-size" = "1.75rem",   # 28px - Subsection titles
    "h4-font-size" = "1.5rem",    # 24px - Card titles
    "h5-font-size" = "1.25rem",   # 20px - Card subtitles
    "h6-font-size" = "1rem",      # 16px - Small headings
    
    # Line heights (unitless for flexibility)
    "line-height-base" = 1.5,     # 24px (16px * 1.5)
    "line-height-sm" = 1.4,
    "line-height-lg" = 1.6,
    
    # Colors (Okabe-Ito palette)
    primary = "#009E73",      # Optimal green
    secondary = "#E69F00",    # High load amber
    danger = "#D55E00",       # Lapse red-orange
    info = "#0072B2",         # Fatigue blue
    success = "#27ae60",
    warning = "#f39c12",
    
    # Grays (WCAG AA compliant)
    "gray-100" = "#f8f9fa",
    "gray-200" = "#e9ecef",
    "gray-300" = "#dee2e6",
    "gray-400" = "#ced4da",
    "gray-500" = "#adb5bd",
    "gray-600" = "#6c757d",
    "gray-700" = "#495057",
    "gray-800" = "#343a40",
    "gray-900" = "#212529"
  )
}

# ============================================================================
# TYPOGRAPHY CONSTANTS
# ============================================================================

#' Typography Scale
#' @export
TYPOGRAPHY <- list(
  # Font sizes (16px base)
  base = "16px",
  sm = "14px",
  lg = "18px",
  xl = "20px",
  xxl = "24px",
  
  # Heading sizes
  h1 = "2.5rem",   # 40px
  h2 = "2rem",     # 32px
  h3 = "1.75rem",  # 28px
  h4 = "1.5rem",   # 24px
  h5 = "1.25rem",  # 20px
  h6 = "1rem",     # 16px
  
  # Line heights (8px grid)
  line_height_tight = 1.25,   # 20px
  line_height_normal = 1.5,   # 24px
  line_height_relaxed = 1.75, # 28px
  
  # Font weights
  light = 300,
  normal = 400,
  medium = 500,
  semibold = 600,
  bold = 700
)

#' Spacing Scale (8px baseline grid)
#' @export
SPACING <- list(
  xs = "4px",    # 0.5 units
  sm = "8px",    # 1 unit
  md = "16px",   # 2 units
  lg = "24px",   # 3 units
  xl = "32px",   # 4 units
  xxl = "40px",  # 5 units
  xxxl = "48px", # 6 units
  
  # Card paddings
  card_padding = "16px",
  card_padding_sm = "12px",
  card_padding_lg = "20px",
  
  # Section spacing
  section_gap = "32px",
  subsection_gap = "24px",
  element_gap = "16px"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Create Section Title with Subtitle
#'
#' @param title Main title text
#' @param subtitle One-line purpose description
#' @param icon Optional icon (emoji or HTML)
#' @return Styled div with title and subtitle
#' @export
section_title <- function(title, subtitle = NULL, icon = NULL) {
  div(
    style = sprintf(
      "margin-bottom: %s; padding-bottom: %s; border-bottom: 2px solid #e9ecef;",
      SPACING$lg,
      SPACING$md
    ),
    
    h2(
      style = sprintf(
        "margin: 0 0 %s 0; 
         font-size: %s; 
         font-weight: %d; 
         color: #2c3e50; 
         line-height: %s;",
        SPACING$sm,
        TYPOGRAPHY$h2,
        TYPOGRAPHY$semibold,
        TYPOGRAPHY$line_height_tight
      ),
      if (!is.null(icon)) HTML(paste0(icon, " ")),
      title
    ),
    
    if (!is.null(subtitle)) {
      p(
        style = sprintf(
          "margin: 0; 
           font-size: %s; 
           color: #6c757d; 
           line-height: %s;",
          TYPOGRAPHY$base,
          TYPOGRAPHY$line_height_normal
        ),
        subtitle
      )
    }
  )
}

#' Create Card Title
#'
#' @param title Card title text
#' @param subtitle Optional subtitle
#' @return Styled h4 element
#' @export
card_title <- function(title, subtitle = NULL) {
  tagList(
    h4(
      style = sprintf(
        "margin: 0 0 %s 0; 
         font-size: %s; 
         font-weight: %d; 
         color: #343a40; 
         line-height: %s;",
        if (!is.null(subtitle)) SPACING$xs else SPACING$md,
        TYPOGRAPHY$h4,
        TYPOGRAPHY$semibold,
        TYPOGRAPHY$line_height_tight
      ),
      title
    ),
    
    if (!is.null(subtitle)) {
      p(
        style = sprintf(
          "margin: 0 0 %s 0; 
           font-size: %s; 
           color: #6c757d; 
           line-height: %s;",
          SPACING$md,
          TYPOGRAPHY$sm,
          TYPOGRAPHY$line_height_normal
        ),
        subtitle
      )
    }
  )
}

#' Create Styled Card
#'
#' @param ... Card content
#' @param padding Padding size (sm, md, lg)
#' @param background Background color
#' @return Styled div
#' @export
styled_card <- function(..., padding = "md", background = "white") {
  padding_value <- switch(
    padding,
    "sm" = SPACING$card_padding_sm,
    "md" = SPACING$card_padding,
    "lg" = SPACING$card_padding_lg,
    SPACING$card_padding
  )
  
  div(
    style = sprintf(
      "background: %s; 
       padding: %s; 
       border-radius: 8px; 
       border: 1px solid #dee2e6; 
       box-shadow: 0 2px 4px rgba(0,0,0,0.05);
       margin-bottom: %s;",
      background,
      padding_value,
      SPACING$md
    ),
    ...
  )
}

#' Create Well Panel with Consistent Spacing
#'
#' @param ... Panel content
#' @param title Optional panel title
#' @return Styled wellPanel
#' @export
styled_well <- function(..., title = NULL) {
  wellPanel(
    style = sprintf(
      "padding: %s; 
       margin-bottom: %s; 
       background: #f8f9fa; 
       border: 1px solid #dee2e6; 
       border-radius: 8px;",
      SPACING$card_padding,
      SPACING$md
    ),
    
    if (!is.null(title)) {
      h5(
        style = sprintf(
          "margin: 0 0 %s 0; 
           font-size: %s; 
           font-weight: %d; 
           color: #495057;",
          SPACING$md,
          TYPOGRAPHY$h5,
          TYPOGRAPHY$semibold
        ),
        title
      )
    },
    
    ...
  )
}

#' Create Tab Subtitle
#'
#' @param text One-line purpose description
#' @return Styled p element
#' @export
tab_subtitle <- function(text) {
  p(
    style = sprintf(
      "margin: %s 0 %s 0; 
       padding: %s %s; 
       font-size: %s; 
       color: #6c757d; 
       background: #f8f9fa; 
       border-left: 4px solid #3498db; 
       border-radius: 4px; 
       line-height: %s;",
      SPACING$sm,
      SPACING$lg,
      SPACING$sm,
      SPACING$md,
      TYPOGRAPHY$base,
      TYPOGRAPHY$line_height_normal
    ),
    text
  )
}

#' Apply Consistent Spacing to fluidRow
#'
#' @param ... Row content
#' @return fluidRow with consistent spacing
#' @export
spaced_row <- function(...) {
  fluidRow(
    style = sprintf("margin-bottom: %s;", SPACING$lg),
    ...
  )
}

# ============================================================================
# ACCESSIBILITY HELPERS
# ============================================================================

#' Check Color Contrast Ratio
#'
#' @param foreground Foreground color (hex)
#' @param background Background color (hex)
#' @return Contrast ratio (numeric)
#' @export
check_contrast <- function(foreground, background) {
  # Convert hex to RGB
  fg_rgb <- col2rgb(foreground) / 255
  bg_rgb <- col2rgb(background) / 255
  
  # Calculate relative luminance
  luminance <- function(rgb) {
    rgb_adjusted <- ifelse(rgb <= 0.03928, 
                           rgb / 12.92, 
                           ((rgb + 0.055) / 1.055)^2.4)
    0.2126 * rgb_adjusted[1] + 0.7152 * rgb_adjusted[2] + 0.0722 * rgb_adjusted[3]
  }
  
  L1 <- luminance(fg_rgb)
  L2 <- luminance(bg_rgb)
  
  # Contrast ratio
  if (L1 > L2) {
    (L1 + 0.05) / (L2 + 0.05)
  } else {
    (L2 + 0.05) / (L1 + 0.05)
  }
}

#' Validate WCAG AA Compliance
#'
#' @param foreground Foreground color
#' @param background Background color
#' @param level "AA" or "AAA"
#' @param size "normal" or "large" (>= 18px or >= 14px bold)
#' @return Logical indicating compliance
#' @export
wcag_compliant <- function(foreground, background, level = "AA", size = "normal") {
  ratio <- check_contrast(foreground, background)
  
  threshold <- if (level == "AAA") {
    if (size == "large") 4.5 else 7.0
  } else {
    if (size == "large") 3.0 else 4.5
  }
  
  ratio >= threshold
}

# ============================================================================
# CUSTOM CSS
# ============================================================================

#' Generate Custom CSS for Dashboard
#'
#' @return HTML style tag
#' @export
dashboard_css <- function() {
  tags$style(HTML(sprintf("
    /* ============================================
       GLOBAL TYPOGRAPHY
       ============================================ */
    
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      font-size: %s;
      line-height: %s;
      color: #2c3e50;
    }
    
    /* Heading hierarchy */
    h1 {
      font-size: %s;
      font-weight: %d;
      line-height: %s;
      margin: 0 0 %s 0;
      color: #2c3e50;
    }
    
    h2 {
      font-size: %s;
      font-weight: %d;
      line-height: %s;
      margin: 0 0 %s 0;
      color: #2c3e50;
    }
    
    h3 {
      font-size: %s;
      font-weight: %d;
      line-height: %s;
      margin: 0 0 %s 0;
      color: #343a40;
    }
    
    h4 {
      font-size: %s;
      font-weight: %d;
      line-height: %s;
      margin: 0 0 %s 0;
      color: #343a40;
    }
    
    h5 {
      font-size: %s;
      font-weight: %d;
      line-height: %s;
      margin: 0 0 %s 0;
      color: #495057;
    }
    
    h6 {
      font-size: %s;
      font-weight: %d;
      line-height: %s;
      margin: 0 0 %s 0;
      color: #6c757d;
    }
    
    /* Paragraph spacing */
    p {
      margin: 0 0 %s 0;
      line-height: %s;
    }
    
    /* ============================================
       CARD STYLING
       ============================================ */
    
    .well, .wellpanel {
      padding: %s;
      margin-bottom: %s;
      border-radius: 8px;
    }
    
    .metric-card {
      padding: %s;
      margin-bottom: %s;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      transition: transform 0.2s ease, box-shadow 0.2s ease;
    }
    
    .metric-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }
    
    /* ============================================
       SPACING UTILITIES
       ============================================ */
    
    .mb-1 { margin-bottom: %s !important; }
    .mb-2 { margin-bottom: %s !important; }
    .mb-3 { margin-bottom: %s !important; }
    .mb-4 { margin-bottom: %s !important; }
    .mb-5 { margin-bottom: %s !important; }
    
    .mt-1 { margin-top: %s !important; }
    .mt-2 { margin-top: %s !important; }
    .mt-3 { margin-top: %s !important; }
    .mt-4 { margin-top: %s !important; }
    .mt-5 { margin-top: %s !important; }
    
    .p-1 { padding: %s !important; }
    .p-2 { padding: %s !important; }
    .p-3 { padding: %s !important; }
    .p-4 { padding: %s !important; }
    .p-5 { padding: %s !important; }
    
    /* ============================================
       ACCESSIBILITY
       ============================================ */
    
    /* Focus indicators */
    button:focus, input:focus, select:focus, textarea:focus {
      outline: 3px solid #3498db;
      outline-offset: 2px;
    }
    
    /* Skip to content link */
    .skip-to-content {
      position: absolute;
      top: -40px;
      left: 0;
      background: #3498db;
      color: white;
      padding: 8px 16px;
      text-decoration: none;
      border-radius: 0 0 4px 0;
      z-index: 10000;
    }
    
    .skip-to-content:focus {
      top: 0;
    }
    
    /* High contrast mode support */
    @media (prefers-contrast: high) {
      body {
        color: #000;
      }
      
      h1, h2, h3, h4, h5, h6 {
        color: #000;
      }
      
      .metric-card {
        border: 2px solid #000;
      }
    }
    
    /* Reduced motion support */
    @media (prefers-reduced-motion: reduce) {
      * {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
      }
    }
    
    /* ============================================
       PLOTLY ADJUSTMENTS
       ============================================ */
    
    .plotly {
      margin-bottom: %s;
    }
    
    /* ============================================
       TABLE STYLING
       ============================================ */
    
    .dataTable {
      font-size: %s;
    }
    
    .dataTable thead th {
      font-weight: %d;
      background: #f8f9fa;
      color: #495057;
      padding: %s;
    }
    
    .dataTable tbody td {
      padding: %s;
      line-height: %s;
    }
  ",
  # Typography values
  TYPOGRAPHY$base,
  TYPOGRAPHY$line_height_normal,
  TYPOGRAPHY$h1, TYPOGRAPHY$semibold, TYPOGRAPHY$line_height_tight, SPACING$lg,
  TYPOGRAPHY$h2, TYPOGRAPHY$semibold, TYPOGRAPHY$line_height_tight, SPACING$lg,
  TYPOGRAPHY$h3, TYPOGRAPHY$semibold, TYPOGRAPHY$line_height_tight, SPACING$md,
  TYPOGRAPHY$h4, TYPOGRAPHY$semibold, TYPOGRAPHY$line_height_tight, SPACING$md,
  TYPOGRAPHY$h5, TYPOGRAPHY$semibold, TYPOGRAPHY$line_height_tight, SPACING$md,
  TYPOGRAPHY$h6, TYPOGRAPHY$medium, TYPOGRAPHY$line_height_tight, SPACING$sm,
  SPACING$md, TYPOGRAPHY$line_height_normal,
  
  # Card spacing
  SPACING$card_padding, SPACING$md,
  SPACING$card_padding, SPACING$md,
  
  # Spacing utilities
  SPACING$sm, SPACING$md, SPACING$lg, SPACING$xl, SPACING$xxl,
  SPACING$sm, SPACING$md, SPACING$lg, SPACING$xl, SPACING$xxl,
  SPACING$sm, SPACING$md, SPACING$lg, SPACING$xl, SPACING$xxl,
  
  # Plotly
  SPACING$lg,
  
  # Tables
  TYPOGRAPHY$sm,
  TYPOGRAPHY$semibold,
  SPACING$sm,
  SPACING$sm,
  TYPOGRAPHY$line_height_normal
  )))
}

# ============================================================================
# CONTRAST VALIDATION
# ============================================================================

#' Validate All Color Combinations
#'
#' @return Data frame with contrast ratios
#' @export
validate_color_contrast <- function() {
  # Test all state colors against white background
  colors_to_test <- list(
    optimal = COLORS$optimal,
    high_load = COLORS$high_load,
    lapse = COLORS$lapse,
    fatigue = COLORS$fatigue
  )
  
  results <- lapply(names(colors_to_test), function(name) {
    color <- colors_to_test[[name]]
    ratio <- check_contrast(color, "#ffffff")
    compliant_aa <- wcag_compliant(color, "#ffffff", "AA", "normal")
    compliant_aaa <- wcag_compliant(color, "#ffffff", "AAA", "normal")
    
    data.frame(
      color_name = name,
      hex = color,
      contrast_ratio = round(ratio, 2),
      wcag_aa = compliant_aa,
      wcag_aaa = compliant_aaa,
      stringsAsFactors = FALSE
    )
  })
  
  do.call(rbind, results)
}
