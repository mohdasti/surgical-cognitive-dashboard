#' Diagnostics Module with Progressive Disclosure
#'
#' @description
#' Implements accordion-style progressive disclosure for ML diagnostics.
#' Prioritizes most impactful sections (Threshold Sandbox, Calibration) first.
#'
#' @details
#' Uses session storage to persist expansion state across page refreshes.

# ============================================================================
# SECTION DEFINITIONS (Priority Order)
# ============================================================================

#' Diagnostics Section Metadata
#' @export
DIAGNOSTICS_SECTIONS <- list(
  threshold_sandbox = list(
    id = "threshold_sandbox",
    title = "🎯 Threshold Sandbox",
    icon = "🎯",
    priority = 1,
    default_expanded = TRUE,
    description = "Interactive threshold tuning with real-time precision-recall tradeoffs. Adjust thresholds and see immediate impact on confusion matrix and F1 scores.",
    impact = "HIGH - Directly informs alert configuration",
    tour_text = "Start here to understand how threshold choices affect alert behavior."
  ),
  
  calibration = list(
    id = "calibration",
    title = "📊 Probability Calibration",
    icon = "📊",
    priority = 2,
    default_expanded = TRUE,
    description = "Reliability analysis of predicted probabilities. Includes calibration curves, ECE/MCE metrics, and Brier scores.",
    impact = "HIGH - Validates that probabilities are trustworthy",
    tour_text = "Check if 70% predicted probability actually means 70% chance of lapse."
  ),
  
  overview = list(
    id = "overview",
    title = "📋 Model Overview",
    icon = "📋",
    priority = 3,
    default_expanded = FALSE,
    description = "Model architecture, hyperparameters, and feature list. Quick reference for model card information.",
    impact = "MEDIUM - Context for understanding model behavior",
    tour_text = "See what features the model uses and how it's configured."
  ),
  
  cross_validation = list(
    id = "cross_validation",
    title = "🔄 Cross-Validation Results",
    icon = "🔄",
    priority = 4,
    default_expanded = FALSE,
    description = "Leave-One-Surgeon-Out (LOSO) evaluation with per-fold metrics, confusion matrices, and PR curves.",
    impact = "MEDIUM - Assesses generalization across surgeons",
    tour_text = "Verify the model works for surgeons it hasn't seen before."
  ),
  
  feature_importance = list(
    id = "feature_importance",
    title = "⚖️ Feature Importance",
    icon = "⚖️",
    priority = 5,
    default_expanded = FALSE,
    description = "XGBoost gain-based importance and SHAP values. Identifies which biosignals drive predictions.",
    impact = "MEDIUM - Explains what the model relies on",
    tour_text = "Discover which biosignals matter most for detecting lapses."
  ),
  
  partial_dependence = list(
    id = "partial_dependence",
    title = "📈 Partial Dependence",
    icon = "📈",
    priority = 6,
    default_expanded = FALSE,
    description = "Marginal effect plots showing how each feature influences predictions while holding others constant.",
    impact = "LOW - Deep dive for researchers",
    tour_text = "Explore how changing one biosignal affects predictions."
  )
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Get Section by ID
#'
#' @param section_id Section identifier
#' @return Section metadata list
#' @export
get_section_metadata <- function(section_id) {
  section <- DIAGNOSTICS_SECTIONS[[section_id]]
  if (is.null(section)) {
    stop(sprintf("Unknown section: %s", section_id))
  }
  section
}

#' Get Sections in Priority Order
#'
#' @return List of sections sorted by priority
#' @export
get_sections_ordered <- function() {
  sections <- DIAGNOSTICS_SECTIONS
  sections[order(sapply(sections, function(s) s$priority))]
}

#' Create Accordion Section UI
#'
#' @param section_meta Section metadata list
#' @param content_ui UI element for section content
#' @return Accordion section HTML
#' @export
create_accordion_section <- function(section_meta, content_ui) {
  section_id <- section_meta$id
  is_expanded <- section_meta$default_expanded
  
  # Determine impact badge color
  impact_color <- switch(
    section_meta$impact,
    "HIGH" = "#27ae60",
    "MEDIUM" = "#f39c12",
    "LOW" = "#95a5a6",
    "#95a5a6"
  )
  
  div(
    class = "accordion-section",
    style = "margin-bottom: 15px; border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden;",
    `data-section-id` = section_id,
    
    # Header (clickable)
    div(
      class = "accordion-header",
      style = sprintf(
        "background: linear-gradient(135deg, #ffffff 0%%, #f8f9fa 100%%); 
         padding: 15px 20px; 
         cursor: pointer; 
         display: flex; 
         justify-content: space-between; 
         align-items: center;
         border-left: 4px solid %s;
         transition: background 0.2s ease;",
        impact_color
      ),
      onclick = sprintf("toggleAccordion('%s')", section_id),
      onmouseover = "this.style.background='linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)'",
      onmouseout = "this.style.background='linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)'",
      
      # Left side: Title and description
      div(
        style = "flex: 1;",
        h4(
          style = "margin: 0 0 5px 0; color: #2c3e50;",
          HTML(paste0(section_meta$icon, " ", section_meta$title))
        ),
        p(
          style = "margin: 0; font-size: 0.9em; color: #7f8c8d;",
          section_meta$description
        ),
        tags$small(
          style = sprintf("color: %s; font-weight: bold; margin-top: 5px; display: inline-block;", impact_color),
          paste0("Impact: ", section_meta$impact)
        )
      ),
      
      # Right side: Expand/collapse icon
      div(
        style = "margin-left: 20px;",
        tags$span(
          id = paste0(section_id, "_icon"),
          style = "font-size: 24px; color: #95a5a6; transition: transform 0.3s ease;",
          if (is_expanded) "▼" else "▶"
        )
      )
    ),
    
    # Content (collapsible)
    div(
      id = section_id,
      class = "accordion-content",
      style = sprintf(
        "padding: 20px; 
         background: white; 
         display: %s; 
         border-top: 1px solid #dee2e6;
         animation: slideDown 0.3s ease;",
        if (is_expanded) "block" else "none"
      ),
      content_ui
    )
  )
}

#' Diagnostics Progressive Disclosure UI
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
mod_diagnostics_progressive_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # CSS for animations and styling
    tags$style(HTML("
      @keyframes slideDown {
        from {
          opacity: 0;
          max-height: 0;
        }
        to {
          opacity: 1;
          max-height: 2000px;
        }
      }
      
      .accordion-header:hover {
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      }
      
      .toc-item {
        padding: 8px 12px;
        margin: 4px 0;
        border-radius: 6px;
        cursor: pointer;
        transition: all 0.2s ease;
        border-left: 3px solid transparent;
      }
      
      .toc-item:hover {
        background: #f8f9fa;
        border-left-color: #3498db;
      }
      
      .toc-item.active {
        background: #e3f2fd;
        border-left-color: #2196f3;
        font-weight: bold;
      }
      
      .toc-item .toc-impact {
        font-size: 0.75em;
        padding: 2px 6px;
        border-radius: 10px;
        margin-left: 8px;
      }
      
      .toc-impact.high { background: #d4edda; color: #155724; }
      .toc-impact.medium { background: #fff3cd; color: #856404; }
      .toc-impact.low { background: #e2e3e5; color: #6c757d; }
    ")),
    
    # JavaScript for accordion toggle
    tags$script(HTML("
      function toggleAccordion(sectionId) {
        var content = document.getElementById(sectionId);
        var icon = document.getElementById(sectionId + '_icon');
        
        if (content.style.display === 'none') {
          content.style.display = 'block';
          icon.textContent = '▼';
          icon.style.transform = 'rotate(0deg)';
          
          // Store state
          sessionStorage.setItem('diag_' + sectionId, 'expanded');
        } else {
          content.style.display = 'none';
          icon.textContent = '▶';
          icon.style.transform = 'rotate(-90deg)';
          
          // Store state
          sessionStorage.setItem('diag_' + sectionId, 'collapsed');
        }
        
        // Scroll to section
        content.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      }
      
      // Restore expansion state on load
      document.addEventListener('DOMContentLoaded', function() {
        setTimeout(function() {
          var sections = document.querySelectorAll('.accordion-section');
          sections.forEach(function(section) {
            var sectionId = section.getAttribute('data-section-id');
            var state = sessionStorage.getItem('diag_' + sectionId);
            
            if (state === 'collapsed') {
              var content = document.getElementById(sectionId);
              var icon = document.getElementById(sectionId + '_icon');
              if (content && icon) {
                content.style.display = 'none';
                icon.textContent = '▶';
              }
            } else if (state === 'expanded') {
              var content = document.getElementById(sectionId);
              var icon = document.getElementById(sectionId + '_icon');
              if (content && icon) {
                content.style.display = 'block';
                icon.textContent = '▼';
              }
            }
          });
        }, 500);
      });
      
      // Expand all / Collapse all helpers
      function expandAllSections() {
        var sections = document.querySelectorAll('.accordion-content');
        var icons = document.querySelectorAll('[id$=\"_icon\"]');
        
        sections.forEach(function(section) {
          section.style.display = 'block';
          sessionStorage.setItem('diag_' + section.id, 'expanded');
        });
        
        icons.forEach(function(icon) {
          icon.textContent = '▼';
        });
      }
      
      function collapseAllSections() {
        var sections = document.querySelectorAll('.accordion-content');
        var icons = document.querySelectorAll('[id$=\"_icon\"]');
        
        sections.forEach(function(section) {
          section.style.display = 'none';
          sessionStorage.setItem('diag_' + section.id, 'collapsed');
        });
        
        icons.forEach(function(icon) {
          icon.textContent = '▶';
        });
      }
    ")),
    
    # Header with controls
    fluidRow(
      column(12,
        div(
          style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                   color: white; 
                   padding: 20px; 
                   border-radius: 10px; 
                   margin-bottom: 20px;",
          
          div(
            style = "display: flex; justify-content: space-between; align-items: center;",
            
            div(
              h2("📊 ML Model Diagnostics", style = "margin: 0 0 10px 0;"),
              p(style = "margin: 0; opacity: 0.9; font-size: 1.05em;",
                "Comprehensive model evaluation and interpretability analysis. ",
                "Sections are ordered by impact — start with Threshold Sandbox and Calibration."
              )
            ),
            
            div(
              style = "display: flex; gap: 10px;",
              actionButton(
                ns("expand_all"),
                "⬇️ Expand All",
                class = "btn-light btn-sm",
                onclick = "expandAllSections()"
              ),
              actionButton(
                ns("collapse_all"),
                "⬆️ Collapse All",
                class = "btn-light btn-sm",
                onclick = "collapseAllSections()"
              )
            )
          )
        )
      )
    ),
    
    # Main layout with TOC and content
    fluidRow(
      # Left sidebar: Table of Contents
      column(3,
        div(
          style = "position: sticky; top: 20px; background: white; padding: 15px; border-radius: 8px; border: 1px solid #dee2e6;",
          
          h5("📑 Table of Contents", style = "margin-top: 0; color: #495057;"),
          
          div(
            id = ns("toc"),
            # TOC items will be generated dynamically
            lapply(get_sections_ordered(), function(section) {
              impact_class <- tolower(section$impact)
              
              div(
                class = "toc-item",
                onclick = sprintf("toggleAccordion('%s')", section$id),
                
                div(
                  style = "display: flex; justify-content: space-between; align-items: center;",
                  
                  div(
                    tags$span(
                      style = "font-size: 1.1em;",
                      section$icon
                    ),
                    tags$span(
                      style = "margin-left: 8px;",
                      gsub("^[^ ]+ ", "", section$title)  # Remove icon from title
                    )
                  ),
                  
                  tags$span(
                    class = paste0("toc-impact ", impact_class),
                    section$impact
                  )
                )
              )
            })
          ),
          
          hr(style = "margin: 15px 0;"),
          
          # Quick stats
          div(
            style = "font-size: 0.85em; color: #6c757d;",
            tags$strong("Quick Stats:"),
            tags$ul(
              style = "margin: 5px 0; padding-left: 20px;",
              tags$li("6 diagnostic sections"),
              tags$li("2 high-impact (expanded)"),
              tags$li("4 supporting (collapsed)")
            )
          )
        )
      ),
      
      # Right side: Accordion content
      column(9,
        # Placeholder for actual content
        # Will be filled by parent module
        uiOutput(ns("accordion_content"))
      )
    )
  )
}

#' Diagnostics Progressive Disclosure Server
#'
#' @param id Module namespace ID
#' @param content_generators Named list of functions that return UI for each section
#' @return List with section state reactives
#' @export
mod_diagnostics_progressive_server <- function(id, content_generators = list()) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Track which sections are expanded
    expanded_sections <- reactiveVal(
      sapply(get_sections_ordered(), function(s) s$default_expanded)
    )
    
    # Generate accordion content
    output$accordion_content <- renderUI({
      sections <- get_sections_ordered()
      
      lapply(sections, function(section) {
        # Get content UI from generator function
        content_ui <- if (!is.null(content_generators[[section$id]])) {
          content_generators[[section$id]]()
        } else {
          div(
            style = "padding: 20px; text-align: center; color: #95a5a6;",
            h5("🚧 Content Coming Soon"),
            p("This section is under development.")
          )
        }
        
        # Create accordion section
        create_accordion_section(section, content_ui)
      })
    })
    
    # Return interface
    list(
      expanded_sections = expanded_sections,
      
      # Helper to check if section is expanded
      is_expanded = function(section_id) {
        reactive({
          expanded_sections()[[section_id]]
        })
      }
    )
  })
}
