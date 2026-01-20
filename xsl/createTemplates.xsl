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
  
  <!-- Get other language for switcher (dynamically) -->
  <xsl:variable name="langList" select="tokenize($languages, ',')"/>
  <xsl:variable name="otherLang" select="
    if ($isBilingual) then
      string($langList[not(. = $lang)][1])
    else ''
                  "/>
  
  <!-- Language labels (add more as needed) -->
  <xsl:variable name="langLabels" as="map(xs:string, xs:string)">
    <xsl:map>
      <xsl:map-entry key="'en'" select="'English'"/>
      <xsl:map-entry key="'fr'" select="'Français'"/>
      <xsl:map-entry key="'de'" select="'Deutsch'"/>
      <xsl:map-entry key="'es'" select="'Español'"/>
      <xsl:map-entry key="'it'" select="'Italiano'"/>
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
      
      <xsl:when test="name() = 'footerContent'">
        <!-- Insert footer markup from properties.xml, converting elements into XHTML -->
        <xsl:for-each select="$properties/footerContent/*">
          <xsl:apply-templates select="." mode="copy-nav-element"/>
        </xsl:for-each>
      </xsl:when>
      
      <xsl:when test="name() = 'uvic-logo'">
        <xsl:variable name="logoPath" select="$properties/files/uvicLogo"/>
        <xsl:variable name="altText">
          <xsl:call-template name="get-text-value">
            <xsl:with-param name="element" select="$properties/footer/uvicLogoAlt"/>
          </xsl:call-template>
        </xsl:variable>
        
        <img src="{$logoPath}" alt="{$altText}" class="uvic-logo-internal"/>
      </xsl:when>
      
      <xsl:when test="name() = 'fontPreloads'">
        <xsl:for-each select="$properties/files/font">
          <link rel="preload" href="{.}" as="font" xmlns="http://www.w3.org/1999/xhtml"/>
        </xsl:for-each>
      </xsl:when>
      
      <xsl:when test="name() = 'bilingualSwitcher'">
        <xsl:choose>
          <xsl:when test="$isBilingual and $otherLang != ''">
            <a id="bilingualSwitcher" href="../{$otherLang}/{{{{currentPage}}}}">
              <xsl:value-of select="hcmc:getLanguageLabel($otherLang)"/>
            </a>
          </xsl:when>
          <xsl:otherwise>
            <!-- No switcher in monolingual mode -->
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
      <xsl:when test="$lang = 'fr' and $element/@fr">
        <xsl:value-of select="$element/@fr"/>
      </xsl:when>
      <xsl:when test="$element/@en">
        <xsl:value-of select="$element/@en"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$element"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Template to get HTML content (unescapes entities) -->
  <xsl:template name="get-html-value">
    <xsl:param name="element"/>
    
    <xsl:variable name="text">
      <xsl:call-template name="get-text-value">
        <xsl:with-param name="element" select="$element"/>
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:value-of select="$text" disable-output-escaping="yes"/>
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
  </xsl:template>  
  
</xsl:stylesheet>