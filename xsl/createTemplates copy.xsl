<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="xs">
  
  <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>
  
  <!-- Parameters for language and template type -->
  <xsl:param name="lang" select="'en'"/>
  <xsl:param name="template" select="'content'"/>
  <xsl:param name="templateFile" select="if ($template = 'content') then '../boilerplate/contentPageTemplate.xml' else '../boilerplate/landingPageTemplate.xml'"/>
  
  <!-- Load properties file -->
  <xsl:variable name="properties" select="document('../properties.xml')/site"/>
  
  <!-- Load image dimensions file -->
  <xsl:variable name="imageDimensions" select="unparsed-text('../utilities/imageDimensions.txt')"/>  
  
  <!-- Load template file -->
  <xsl:variable name="templateDoc" select="document($templateFile)"/>
  
  <!-- Main template -->
  <xsl:template match="/">
    <xsl:apply-templates select="$templateDoc" mode="process-template"/>
  </xsl:template>
  
  <!-- Process template elements -->
  <xsl:template match="node() | @*" mode="process-template">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="process-template"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Process attributes with placeholders -->
  <xsl:template match="@*[contains(., '{?') and contains(., '}')]" mode="process-template" priority="1">
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
        <xsl:call-template name="get-text-value">
          <xsl:with-param name="element" select="$properties/metadata/splashSubtitle"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'splashWhereWhen'">
        <xsl:call-template name="build-where-when"/>
      </xsl:when>
      
      <xsl:when test="name() = 'navigationMenu' or name() = 'splashNavigationMenu'">
        <xsl:call-template name="build-navigation"/>
      </xsl:when>
      
      <xsl:when test="name() = 'copyrightText'">
        <xsl:call-template name="get-html-value">
          <xsl:with-param name="element" select="$properties/footer/copyright-text"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'citationText'">
        <xsl:call-template name="get-text-value">
          <xsl:with-param name="element" select="$properties/footer/citation-text"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'acknowledgementsText'">
        <xsl:call-template name="get-html-value">
          <xsl:with-param name="element" select="$properties/footer/acknowledgements-text"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="name() = 'uvic-logo'">
        <xsl:variable name="logoPath" select="$properties/files/uvic-logo"/>
        <xsl:variable name="altText">
          <xsl:call-template name="get-text-value">
            <xsl:with-param name="element" select="$properties/footer/uvic-logo-alt"/>
          </xsl:call-template>
        </xsl:variable>
        
        <img src="{$logoPath}" alt="{$altText}" class="uvic-logo-internal"/>
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
      <xsl:when test="contains($text, '{?cssFile}')">
        <xsl:value-of select="replace($text, '\{\?cssFile\}', $properties/files/css)"/>
      </xsl:when>

      <xsl:when test="contains($text, '{?jsFile}')">
        <xsl:value-of select="replace($text, '\{\?jsFile\}', $properties/files/js)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?font}')">
        <xsl:value-of select="replace($text, '\{\?font\}', $properties/files/font)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?metaDescription}')">
        <xsl:variable name="description">
          <xsl:call-template name="get-text-value">
            <xsl:with-param name="element" select="$properties/metadata/meta-description"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="replace($text, '\{\?metaDescription\}', string($description))"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?faviconIco}')">
        <xsl:value-of select="replace($text, '\{\?faviconIco\}', $properties/files/favicon-ico)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?faviconSvg}')">
        <xsl:value-of select="replace($text, '\{\?faviconSvg\}', $properties/files/favicon-svg)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?siteManifest}')">
        <xsl:value-of select="replace($text, '\{\?siteManifest\}', $properties/files/site-manifest)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?homeUrl}')">
        <xsl:call-template name="get-text-value">
          <xsl:with-param name="element" select="$properties/urls/home"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?mobileLogo}')">
        <xsl:value-of select="replace($text, '\{\?mobileLogo\}', $properties/files/mobile-logo)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?siteLogo}')">
        <xsl:value-of select="replace($text, '\{\?siteLogo\}', $properties/files/site-logo)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?organization}')">
        <xsl:call-template name="get-text-value">
          <xsl:with-param name="element" select="$properties/metadata/organization"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?mobileFooterLogo}')">
        <xsl:value-of select="replace($text, '\{\?mobileFooterLogo\}', $properties/files/mobile-footer-logo)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?footerLogo}')">
        <xsl:value-of select="replace($text, '\{\?footerLogo\}', $properties/files/footer-logo)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?footerLogoAlt}')">
        <xsl:call-template name="get-text-value">
          <xsl:with-param name="element" select="$properties/footer/footer-logo-alt"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?uvicUrl}')">
        <xsl:value-of select="replace($text, '\{\?uvicUrl\}', 'https://hcmc.uvic.ca')"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?uvicLogo}')">
        <xsl:value-of select="replace($text, '\{\?uvicLogo\}', $properties/files/uvic-logo)"/>
      </xsl:when>
      
      <xsl:when test="contains($text, '{?uvicLogoAlt}')">
        <xsl:call-template name="get-text-value">
          <xsl:with-param name="element" select="$properties/footer/uvic-logo-alt"/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- Generic handler for image dimensions -->
      <xsl:when test="matches($text, '\{\?.*Width\}')">
        <xsl:variable name="placeholder" select="substring-before(substring-after($text, '{?'), 'Width}')"/>
        <xsl:variable name="imagePath" select="$properties/files/*[local-name() = replace($placeholder, 'Width', '')]"/>
        <xsl:variable name="width">
          <xsl:call-template name="get-image-dimensions">
            <xsl:with-param name="imagePath" select="$imagePath"/>
            <xsl:with-param name="dimension" select="'width'"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="replace($text, '\{\?' || $placeholder || 'Width\}', if ($width != '') then $width else '100')"/>
      </xsl:when>
      
      <xsl:when test="matches($text, '\{\?.*Height\}')">
        <xsl:variable name="placeholder" select="substring-before(substring-after($text, '{?'), 'Height}')"/>
        <xsl:variable name="imagePath" select="$properties/files/*[local-name() = replace($placeholder, 'Height', '')]"/>
        <xsl:variable name="height">
          <xsl:call-template name="get-image-dimensions">
            <xsl:with-param name="imagePath" select="$imagePath"/>
            <xsl:with-param name="dimension" select="'height'"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="replace($text, '\{\?' || $placeholder || 'Height\}', if ($height != '') then $height else '26')"/>
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
    <xsl:for-each select="$properties/navigation/menu">
      <li>
        <a href="{@href}">
          <xsl:call-template name="get-text-value">
            <xsl:with-param name="element" select="."/>
          </xsl:call-template>
        </a>
      </li>
    </xsl:for-each>
  </xsl:template>
  
  <!-- Template to get image dimensions -->
  <xsl:template name="get-image-dimensions">
    <xsl:param name="imagePath"/>
    <xsl:param name="dimension"/> <!-- 'width' or 'height' -->
    
    <xsl:variable name="lines" select="tokenize($imageDimensions, '\n')"/>
    <xsl:variable name="imageLine" select="$lines[starts-with(., $imagePath)][1]"/>
    
    <xsl:if test="$imageLine != ''">
      <xsl:variable name="parts" select="tokenize($imageLine, '\s+')"/>
      <xsl:variable name="dimensionsPart" select="$parts[2]"/>
      <xsl:choose>
        <xsl:when test="$dimension = 'width'">
          <xsl:value-of select="substring-before($dimensionsPart, 'x')"/>
        </xsl:when>
        <xsl:when test="$dimension = 'height'">
          <xsl:value-of select="substring-after($dimensionsPart, 'x')"/>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>