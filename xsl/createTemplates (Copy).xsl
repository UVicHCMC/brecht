<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                exclude-result-prefixes="#all" 
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:hcmc="http://hcmc.uvic.ca/ns"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                version="3.0">

  <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>
  
  <!-- Load properties file -->
  <xsl:variable name="propertiesDoc" select="document(resolve-uri('../properties.xml', base-uri(/)))"/>
  <xsl:variable name="properties" select="$propertiesDoc/site"/>
  
  <!-- Parameters for language -->
  <xsl:param name="lang" select="'en'"/>
  <xsl:param name="languages" select="'en'"/>
  
  <!-- Check if bilingual -->
  <xsl:variable name="isBilingual" select="contains($languages, ',')"/>
  
  <!-- Get list of all languages -->
  <xsl:variable name="langList" select="tokenize($languages, ',')" />
  
  <!-- Build language labels map from properties.xml -->
  <xsl:variable name="langLabels" as="map(xs:string, xs:string)">
    <xsl:map>
      <xsl:for-each select="$properties/languages/lang">
        <xsl:map-entry key="string(@code)" select="string(@label)"/>
      </xsl:for-each>
    </xsl:map>
  </xsl:variable>
  
  <!-- Get label for other language, fallback to capitalized code -->
  <xsl:function name="hcmc:getLanguageLabel" as="xs:string">
    <xsl:param name="langCode" as="xs:string"/>
    <xsl:sequence select="
      if (map:contains($langLabels, $langCode)) then
        map:get($langLabels, $langCode)
      else
        upper-case(substring($langCode, 1, 1)) || substring($langCode, 2)
                    "/>
  </xsl:function>

  <!-- Main template -->
  <xsl:template match="/">
    <xsl:apply-templates select="." mode="process-template"/>
  </xsl:template>
  
  <!-- Process template elements -->
  <xsl:template match="xhtml:* | @* | node()" mode="process-template">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="process-template"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Process attributes with placeholders -->
  <xsl:template match="@*[contains(., '{?') and contains(., '}')]" mode="process-template" priority="2">
    <xsl:attribute name="{name()}">
      <xsl:call-template name="replace-placeholders">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
    </xsl:attribute>
  </xsl:template>
  
  <!-- Process processing instructions -->
  <xsl:template match="processing-instruction()" mode="process-template" priority="1">
    <xsl:choose>
      <xsl:when test="name() = 'siteTitle'">
        <xsl:call-template name="get-text-value">
          <xsl:with-param name="element" select="$properties/metadata/siteTitle"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'splashTitle'">
        <xsl:call-template name="get-text-value">
          <xsl:with-param name="element" select="$properties/metadata/splashTitle"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'splashSubtitle'">
        <xsl:call-template name="get-html-value">
          <xsl:with-param name="element" select="$properties/metadata/splashSubtitle"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'splashWhereWhen'">
        <xsl:call-template name="build-where-when"/>
      </xsl:when>
      
      <xsl:when test="name() = 'navigation' or name() = 'navigationMenu' or name() = 'splashNavigationMenu'">
        <xsl:call-template name="build-navigation"/>
      </xsl:when>
      
      <xsl:when test="name() = 'copyrightText'">
        <xsl:call-template name="get-html-value">
          <xsl:with-param name="element" select="$properties/footer/copyrightText"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'citationText'">
        <xsl:call-template name="get-text-value">
          <xsl:with-param name="element" select="$properties/footer/citationText"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'acknowledgementsText'">
        <xsl:call-template name="get-html-value">
          <xsl:with-param name="element" select="$properties/footer/acknowledgementsText"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'footer-content'">
        <!-- Insert footer markup from properties.xml, converting elements into XHTML -->
        <xsl:for-each select="$properties/footer-content/*">
          <xsl:apply-templates select="." mode="copy-footer-element"/>
        </xsl:for-each>
      </xsl:when>
      
      <xsl:when test="name() = 'uvic-logo'">
        <xsl:variable name="uvicLogo" select="$properties/uvic-logo"/>
        <xsl:variable name="altText">
          <xsl:call-template name="get-text-value">
            <xsl:with-param name="element" select="$uvicLogo/alt"/>
          </xsl:call-template>
        </xsl:variable>
        <a href="{$uvicLogo/href}">
          <img src="{$uvicLogo/src}" alt="{$altText}"/>
        </a>
      </xsl:when>
      
      <xsl:when test="name() = 'fontPreloads'">
        <xsl:for-each select="$properties/files/font">
          <link rel="preload" href="{.}" as="font" xmlns="http://www.w3.org/1999/xhtml"/>
        </xsl:for-each>
      </xsl:when>
      
      <xsl:when test="name() = 'splash-logo'">
        <xsl:variable name="logoSrc" select="$properties/splash-logo/src"/>
        <xsl:variable name="langChild" select="$properties/splash-logo/*[local-name() = $lang]"/>
        <xsl:variable name="altText">
          <xsl:choose>
            <xsl:when test="$langChild">
              <xsl:value-of select="$langChild"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$properties/splash-logo/en"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <img class="splash-logo" src="{$logoSrc}" width="1500" height="1340" alt="{$altText}"/>
      </xsl:when>
      
      <xsl:when test="name() = 'lang-chooser'">
        <xsl:choose>
          <xsl:when test="count($langList) = 2">
            <!-- Two languages: simple link to other language -->
            <xsl:variable name="otherLang" select="string($langList[not(. = $lang)][1])"/>
            <xsl:variable name="otherLangLabel" select="upper-case(string($otherLang))"/>
            <xsl:variable name="ariaLabel">
              <xsl:call-template name="get-text-value">
                <xsl:with-param name="element" select="$properties/lang-chooser/aria-label"/>
              </xsl:call-template>
            </xsl:variable>
            <a class="lang-chooser" href="../{$otherLang}/index.html" 
               aria-label="{$ariaLabel}" lang="{$otherLang}">
              <xsl:value-of select="$otherLangLabel"/>
            </a>
          </xsl:when>
          <xsl:when test="count($langList) gt 2">
            <!-- Three or more languages: dropdown menu -->
            <div id="languageSwitcher" class="language-switcher-dropdown">
              <button class="language-switcher-button">
                <xsl:value-of select="hcmc:getLanguageLabel($lang)"/>
                <span class="dropdown-arrow">▼</span>
              </button>
              <ul class="language-switcher-menu">
                <xsl:for-each select="$langList[not(. = $lang)]">
                  <li>
                    <a href="../{.}/{{{{currentPage}}}}">
                      <xsl:value-of select="hcmc:getLanguageLabel(.)"/>
                    </a>
                  </li>
                </xsl:for-each>
              </ul>
            </div>
          </xsl:when>
          <xsl:otherwise>
            <!-- Monolingual: no switcher -->
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <xsl:when test="name() = 'bilingualSwitcher'">
        <xsl:choose>
          <xsl:when test="count($langList) = 2">
            <!-- Two languages: simple link to other language -->
            <xsl:variable name="otherLang" select="string($langList[not(. = $lang)][1])"/>
            <xsl:variable name="otherLangLabel" select="upper-case(string($otherLang))"/>
            <xsl:variable name="otherLangName" select="hcmc:getLanguageLabel($otherLang)"/>
            <a class="lang-chooser" href="../{$otherLang}/index.html" 
               aria-label="Switch site language to {$otherLangName}" lang="{$otherLang}">
              <xsl:value-of select="$otherLangLabel"/>
            </a>
          </xsl:when>
          <xsl:when test="count($langList) gt 2">
            <!-- Three or more languages: dropdown menu -->
            <div id="languageSwitcher" class="language-switcher-dropdown">
              <button class="language-switcher-button">
                <xsl:value-of select="hcmc:getLanguageLabel($lang)"/>
                <span class="dropdown-arrow">▼</span>
              </button>
              <ul class="language-switcher-menu">
                <xsl:for-each select="$langList[not(. = $lang)]">
                  <li>
                    <a href="../{.}/{{{{currentPage}}}}">
                      <xsl:value-of select="hcmc:getLanguageLabel(.)"/>
                    </a>
                  </li>
                </xsl:for-each>
              </ul>
            </div>
          </xsl:when>
          <xsl:otherwise>
            <!-- Monolingual: no switcher -->
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <xsl:when test="name() = 'docContent'">
        <!-- This will be replaced by actual document content during build -->
        <xsl:processing-instruction name="docContent"/>
      </xsl:when>
      
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Template to replace placeholders in attribute values -->
  <xsl:template name="replace-placeholders">
    <xsl:param name="text"/>
    
    <xsl:choose>
      <xsl:when test="matches($text, '\{\?[a-zA-Z]+\}')">
        <xsl:variable name="placeholder" select="substring-before(substring-after($text, '{?'), '}')"/>
        
        <!-- Try to find in files (these are always simple text values) -->
        <xsl:variable name="fileValue" select="$properties/files/*[local-name() = $placeholder]"/>
        
        <!-- Try to find in urls (may have language attributes) -->
        <xsl:variable name="urlElement" select="$properties/urls/*[local-name() = $placeholder]"/>
        
        <!-- Try to find anywhere else in properties -->
        <xsl:variable name="anyElement" select="$properties//*[local-name() = $placeholder]"/>
        
        <xsl:choose>
          <!-- Files: direct text value -->
          <xsl:when test="$fileValue">
            <xsl:value-of select="replace($text, concat('\{\?', $placeholder, '\}'), string($fileValue))"/>
          </xsl:when>
          
          <!-- URLs: may need language handling -->
          <xsl:when test="$urlElement">
            <xsl:choose>
              <xsl:when test="$urlElement/@*[local-name() = $lang]">
                <xsl:variable name="urlValue">
                  <xsl:call-template name="get-text-value">
                    <xsl:with-param name="element" select="$urlElement"/>
                  </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="replace($text, concat('\{\?', $placeholder, '\}'), string($urlValue))"/>
              </xsl:when>
              <xsl:otherwise>
                <!-- URL has no language attributes, use as-is -->
                <xsl:value-of select="replace($text, concat('\{\?', $placeholder, '\}'), string($urlElement))"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          
          <!-- Other elements: check if they need language handling -->
          <xsl:when test="$anyElement">
            <xsl:choose>
              <xsl:when test="$anyElement/@*[local-name() = $lang]">
                <xsl:variable name="value">
                  <xsl:call-template name="get-text-value">
                    <xsl:with-param name="element" select="$anyElement"/>
                  </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="replace($text, concat('\{\?', $placeholder, '\}'), string($value))"/>
              </xsl:when>
              <xsl:otherwise>
                <!-- Element exists but has no language attributes - use text content -->
                <xsl:value-of select="replace($text, concat('\{\?', $placeholder, '\}'), string($anyElement))"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          
          <xsl:otherwise>
            <!-- Not found anywhere - output warning and leave blank -->
            <xsl:message>Warning: No value found for placeholder {?<xsl:value-of select="$placeholder"/>}</xsl:message>
            <xsl:value-of select="replace($text, concat('\{\?', $placeholder, '\}'), '')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Template to get text value based on language -->
  <xsl:template name="get-text-value">
    <xsl:param name="element"/>
    
    <xsl:choose>
      <!-- Check for child element matching current language -->
      <xsl:when test="$element/*[local-name() = $lang]">
        <xsl:value-of select="$element/*[local-name() = $lang]"/>
      </xsl:when>
      <!-- Check for attribute matching current language -->
      <xsl:when test="$element/@*[local-name() = $lang]">
        <xsl:value-of select="$element/@*[local-name() = $lang]"/>
      </xsl:when>
      <!-- Fallback to text content -->
      <xsl:otherwise>
        <xsl:value-of select="$element"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Template to get HTML content (copy nodes for proper HTML) -->
  <xsl:template name="get-html-value">
    <xsl:param name="element"/>
    <xsl:message>DEBUG: get-html-value called for lang=<xsl:value-of select="$lang"/></xsl:message>
    <xsl:choose>
      <!-- If element has child element for current language, copy its children -->
      <xsl:when test="$element/*[local-name() = $lang]">
        <xsl:message>DEBUG: found child element for lang=<xsl:value-of select="$lang"/></xsl:message>
        <xsl:copy-of select="$element/*[local-name() = $lang]/node()"/>
      </xsl:when>
      <!-- If element has attribute for current language, output with disabled escaping -->
      <xsl:when test="$element/@*[local-name() = $lang]">
        <xsl:message>DEBUG: found attribute for lang=<xsl:value-of select="$lang"/></xsl:message>
        <xsl:value-of select="$element/@*[local-name() = $lang]" disable-output-escaping="yes"/>
      </xsl:when>
      <!-- Fallback: copy all child nodes -->
      <xsl:otherwise>
        <xsl:message>DEBUG: fallback to all child nodes for lang=<xsl:value-of select="$lang"/></xsl:message>
        <xsl:copy-of select="$element/node()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Template to build where/when section -->
  <xsl:template name="build-where-when">
    <div class="place">
      <xsl:call-template name="get-text-value">
        <xsl:with-param name="element" select="$properties/metadata/splashWhereWhen/place"/>
      </xsl:call-template>
    </div>
    <div class="date">
      <xsl:call-template name="get-text-value">
        <xsl:with-param name="element" select="$properties/metadata/splashWhereWhen/date"/>
      </xsl:call-template>
    </div>
    <div class="location">
      <xsl:call-template name="get-text-value">
        <xsl:with-param name="element" select="$properties/metadata/splashWhereWhen/location"/>
      </xsl:call-template>
    </div>
  </xsl:template>
  
  <!-- Template to build navigation menu -->
  <xsl:template name="build-navigation">
    <xsl:for-each select="$properties/navigation/*">
      <xsl:apply-templates select="." mode="copy-nav-element"/>
    </xsl:for-each>
  </xsl:template>
  
  <!-- Template to copy navigation elements and resolve language attributes -->
  <xsl:template match="*" mode="copy-nav-element">
    <xsl:choose>
      <!-- Transform <item> to <li><a> -->
      <xsl:when test="local-name() = 'item'">
        <li>
          <a class="item">
            <xsl:copy-of select="@*[not(local-name() = map:keys($langLabels))]"/>
            <!-- Get text from child language elements -->
            <xsl:choose>
              <xsl:when test="*[local-name() = $lang]">
                <xsl:value-of select="*[local-name() = $lang]"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="*[1]"/>
              </xsl:otherwise>
            </xsl:choose>
          </a>
        </li>
      </xsl:when>
      
      <!-- Handle img elements with language attributes for alt text -->
      <xsl:when test="local-name() = 'img' and (@*[local-name() = $lang] or @en)">
        <img>
          <!-- Copy all non-language attributes -->
          <xsl:copy-of select="@*[not(local-name() = map:keys($langLabels))]"/>
          <!-- Add alt attribute from language-specific attribute -->
          <xsl:attribute name="alt">
            <xsl:call-template name="get-text-value">
              <xsl:with-param name="element" select="."/>
            </xsl:call-template>
          </xsl:attribute>
        </img>
      </xsl:when>
      
      <!-- For other elements, copy normally -->
      <xsl:otherwise>
        <xsl:element name="{local-name()}">
          <!-- Copy all non-language attributes -->
          <xsl:copy-of select="@*[not(local-name() = map:keys($langLabels))]"/>
          
          <!-- Process child elements and text -->
          <xsl:choose>
            <xsl:when test="@*[local-name() = $lang] or @en">
              <!-- Element has language attributes, get text value -->
              <xsl:call-template name="get-text-value">
                <xsl:with-param name="element" select="."/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="*">
              <!-- Element has children, process them recursively -->
              <xsl:apply-templates select="*" mode="copy-nav-element"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- Element has text content, copy it -->
              <xsl:value-of select="."/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Template to copy footer elements and process nested PIs -->
  <xsl:template match="*" mode="copy-footer-element">
    <xsl:choose>
      <!-- Transform <items> to <ul class="footer-items"> -->
      <xsl:when test="local-name() = 'items'">
        <div class="footer-container">
          <ul class="footer-items">
            <xsl:apply-templates select="*" mode="copy-footer-element"/>
          </ul>
        </div>
      </xsl:when>
      
      <!-- Transform <item> to <li> -->
      <xsl:when test="local-name() = 'item'">
        <li>
          <xsl:apply-templates select="node()" mode="copy-footer-element"/>
        </li>
      </xsl:when>
      
      <!-- For other elements, copy them -->
      <xsl:otherwise>
        <xsl:element name="{local-name()}">
          <xsl:copy-of select="@*"/>
          <xsl:apply-templates select="node()" mode="copy-footer-element"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Process PIs inside footer -->
  <xsl:template match="processing-instruction()" mode="copy-footer-element">
    <xsl:apply-templates select="." mode="process-template"/>
  </xsl:template>
  
  <!-- Copy text nodes in footer -->
  <xsl:template match="text()" mode="copy-footer-element">
    <xsl:value-of select="normalize-space(.)"/>
  </xsl:template>
  
</xsl:stylesheet>