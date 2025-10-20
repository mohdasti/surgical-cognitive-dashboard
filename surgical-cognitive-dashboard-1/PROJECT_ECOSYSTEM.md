# Surgical Cognitive Monitoring Ecosystem

## 🌐 Overview

The **Surgical Cognitive Monitoring** project consists of two complementary repositories working together to advance surgical safety through cognitive monitoring:

```
┌─────────────────────────────────────────────────────────┐
│     Surgical Cognitive Monitoring Ecosystem             │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  🏥 Production Dashboard      🧪 Training Lab           │
│  (surgical-cognitive-         (surgical-training-       │
│   dashboard)                   lab)                     │
│                                                          │
│  ✅ Real-time monitoring       ✅ Research tool         │
│  ✅ Clinical deployment        ✅ Education platform    │
│  ✅ Patient safety            ✅ Theory exploration     │
│  ✅ Zero errors               ✅ Experimentation        │
│                                                          │
│  Used by:                     Used by:                  │
│  • Hospitals                  • Researchers             │
│  • Clinicians                 • Graduate students       │
│  • Safety officers            • Cognitive scientists    │
│                               • Course instructors      │
│                                                          │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
               GitHub Project (Coming Soon)
           Unified roadmap and issue tracking
```

---

## 🏥 Production Dashboard (This Repository)

**Repository:** [surgical-cognitive-dashboard](https://github.com/mohdasti/surgical-cognitive-dashboard)

### **Purpose:**
Real-time surgical cognitive state monitoring for clinical environments.

### **Key Features:**
- ✅ Production-ready, zero runtime errors
- ✅ Six biosignals with real-time feature extraction
- ✅ ML-driven cognitive state detection
- ✅ Interactive GT live table with reference ranges
- ✅ Comprehensive ML diagnostics suite
- ✅ Pure CSS implementation (no opacity issues)

### **Target Users:**
- Hospital IT administrators
- Surgical safety officers
- Clinical researchers
- Operating room staff

### **Status:** Production Ready ✅

---

## 🧪 Training Lab (Companion Repository)

**Repository:** [surgical-training-lab](https://github.com/mohdasti/surgical-training-lab)

### **Purpose:**
Interactive research and educational tool for exploring cognitive theory paradigms.

### **Key Features:**
- ✅ Three cognitive paradigms (AGT, Resource Competition, Vigilance Decrement)
- ✅ Side-by-side comparison mode
- ✅ Scenario presets for common situations
- ✅ Extensive theory documentation
- ✅ Parameter adjustment and exploration
- ✅ Educational overlays and explanations

### **Target Users:**
- Graduate students
- Cognitive neuroscience researchers
- Course instructors
- Algorithm developers

### **Status:** Research Tool 🔬

---

## 🆚 When to Use Which?

See the **[detailed comparison table](COMPARISON.md)** for comprehensive guidance.

### **Quick Reference:**

| **Scenario** | **Tool** | **Why** |
|-------------|---------|---------|
| Monitor a live surgery | 🏥 **Dashboard** | Reliability, patient safety |
| Deploy in hospital | 🏥 **Dashboard** | Production-grade stability |
| Teach AGT in class | 🧪 **Training Lab** | Interactive theory exploration |
| Prototype new algorithm | 🧪 **Training Lab** | Flexibility, experimentation |
| Research study | 🧪 **Training Lab** | Adjustable parameters |
| Validate for clinical use | 🏥 **Dashboard** | Fixed, validated algorithms |

---

## 🔄 Development Flow

### **Research → Clinical Translation Pipeline**

```
🧪 Training Lab                🏥 Production Dashboard
     │                              │
     ├─ 1. Prototype              │
     │     New paradigm           │
     │                             │
     ├─ 2. Validate               │
     │     With research data     │
     │                             │
     ├─ 3. Refine                 │
     │     Parameters & UI        │
     │                             │
     └─────────────────────────────→ 4. Port
                                   │     Stable features
                                   │
                                   ├─ 5. Test
                                   │     Production standards
                                   │
                                   ├─ 6. Optimize
                                   │     Performance & reliability
                                   │
                                   └─ 7. Deploy ✅
                                        Clinical use
```

### **Example: Adding AGT to Production**

1. **Training Lab:** Implement AGT paradigm
2. **Training Lab:** Test with 100 simulated cases
3. **Training Lab:** Gather user feedback from researchers
4. **Training Lab:** Refine parameters based on literature
5. **Dashboard:** Port validated implementation
6. **Dashboard:** Add comprehensive error handling
7. **Dashboard:** Performance optimization
8. **Dashboard:** Clinical validation study
9. **Dashboard:** Hospital deployment

---

## 📚 Shared Foundation

Both tools share the same scientific foundation:

### **Evidence Base:**
- 20+ peer-reviewed studies
- Validated biosignal parameters
- Cognitive neuroscience theory
- Surgical human factors research

### **Core Technologies:**
- R 4.x
- Shiny web framework
- bslib for modern UI
- plotly for interactive visualizations
- XGBoost for ML inference

### **License:**
- AGPL v3 for both repositories
- Open source transparency
- Research reproducibility
- Web service copyleft

---

## 🚀 Getting Started

### **For Clinical Use:**

```bash
# Clone production dashboard
git clone https://github.com/mohdasti/surgical-cognitive-dashboard.git
cd surgical-cognitive-dashboard/surgical-cognitive-dashboard-1

# Install dependencies
Rscript -e "install.packages(c('shiny', 'bslib', 'plotly', ...))"

# Run the app
cd shiny_app
./run_app.sh

# Access at http://localhost:3838
```

### **For Research/Education:**

```bash
# Clone training lab
git clone https://github.com/mohdasti/surgical-training-lab.git
cd surgical-training-lab

# Install dependencies
Rscript -e "install.packages(c('shiny', 'bslib', 'plotly', ...))"

# Run the app
Rscript -e "shiny::runApp('app.R', launch.browser=TRUE)"
```

---

## 🎯 GitHub Project (Coming Soon)

A unified GitHub Project will track development across both repositories:

### **Project Views:**
- **All Items:** Combined backlog
- **Production Only:** Clinical features
- **Research Only:** Experimental features
- **Roadmap:** Timeline view of milestones

### **Label Strategy:**
- 🏥 `production` - Dashboard features
- 🧪 `research` - Training Lab features
- 📚 `education` - Educational content
- 🔬 `theory` - Cognitive science implementations

### **Setup Instructions:**
See **[GitHub Project Setup Guide](https://github.com/mohdasti/surgical-training-lab/blob/main/GITHUB_PROJECT_SETUP.md)** for complete instructions.

---

## 📖 Documentation

### **Production Dashboard:**
- [Main README](../README.md)
- [Evidence Base Summary](BIOSIGNAL_EVIDENCE_SUMMARY.md)
- [Implementation Guides](MASTER_IMPLEMENTATION_GUIDE.md)
- [Comparison Table](COMPARISON.md)

### **Training Lab:**
- [Training Lab README](https://github.com/mohdasti/surgical-training-lab/blob/main/README.md)
- [Setup Guide](https://github.com/mohdasti/surgical-training-lab/blob/main/SETUP.md)
- [Comparison Table](https://github.com/mohdasti/surgical-training-lab/blob/main/COMPARISON.md)
- [GitHub Project Setup](https://github.com/mohdasti/surgical-training-lab/blob/main/GITHUB_PROJECT_SETUP.md)

---

## 🤝 Contributing

### **To Production Dashboard:**
- Focus on reliability and patient safety
- Extensive testing required
- Follow production code standards
- Clinical validation evidence needed

### **To Training Lab:**
- Experimental features welcome
- New paradigm implementations encouraged
- Educational materials appreciated
- Research methodology discussions

---

## 📜 Citation

**For the Production Dashboard:**
```bibtex
@software{dastgheib2025dashboard,
  author = {Dastgheib, Mohammad},
  title = {Surgical Cognitive Dashboard: Real-time Monitoring System},
  year = {2025},
  url = {https://github.com/mohdasti/surgical-cognitive-dashboard},
  note = {Production-ready clinical monitoring tool}
}
```

**For the Training Lab:**
```bibtex
@software{dastgheib2025traininglab,
  author = {Dastgheib, Mohammad},
  title = {Surgical Training Lab: Interactive Cognitive Theory Exploration},
  year = {2025},
  url = {https://github.com/mohdasti/surgical-training-lab},
  note = {Research and educational tool}
}
```

**For the Ecosystem (both tools):**
```bibtex
@software{dastgheib2025ecosystem,
  author = {Dastgheib, Mohammad},
  title = {Surgical Cognitive Monitoring Ecosystem},
  year = {2025},
  url = {https://github.com/mohdasti},
  note = {Integrated research-to-clinical translation platform}
}
```

---

## 👨‍💻 Author

**Mohammad Dastgheib**  
PhD Candidate, Cognitive Neuroscience  
Portfolio: [mdastgheib.com](https://mdastgheib.com)  
LinkedIn: [mohdasti](https://linkedin.com/in/mohdasti)  
GitHub: [@mohdasti](https://github.com/mohdasti)

---

## 💡 Philosophy

> **"Research tools enable discovery. Production tools enable deployment. Together, they enable impact."**

This ecosystem embodies the principle that **research and practice must inform each other:**

- **Training Lab** provides the creative space to explore and discover
- **Production Dashboard** provides the rigorous environment to validate and deploy
- **Continuous flow** between them ensures evidence-based innovation

By maintaining both tools, we ensure:
- 🔬 Research is grounded in real-world needs
- 🏥 Clinical tools are informed by cutting-edge science
- 📚 Students learn both theory AND practice
- 🚀 Innovation can safely reach patients

---

*This ecosystem represents a complete research-to-clinical translation pipeline for surgical cognitive monitoring.*





