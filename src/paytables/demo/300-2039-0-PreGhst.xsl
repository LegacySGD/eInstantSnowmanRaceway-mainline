<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNames)
					{
						var scenario = getScenario(jsonContext);
						var chosenSnowmans = getWinningNumbers(scenario);
						var outcomeNums = getOutcomeData(scenario, 0);
						var outcomePrizes = getOutcomeData(scenario, 1);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');
						var prizeList = (prizeNames.substring(1)).split(',');

						registerDebugText("Chosen Snowmans: " + chosenSnowmans);
						registerDebugText("All Snowmans: " + prizeList);						
						
						
						//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////			
						// Print Translation Table to !DEBUG
						var index = 1;
						registerDebugText("Translation Table");
						while(index < translations.item(0).getChildNodes().getLength())
						{
							var childNode = translations.item(0).getChildNodes().item(index);
							registerDebugText(childNode.getAttribute("key") + ": " +  childNode.getAttribute("value"));
							index += 2;
						}
						// Output winning numbers table.
						var r = [];
						
						var totalCounts = new Array(8);
						for(var i = 0; i<8; i++){
							totalCounts[i] = 0;
						}
						var totalMultipliers = new Array(5);
						for(var i = 0; i<5; i++){
							totalMultipliers[i] = 0;
						}
						
						var outcomeStrings = getTurnStrings(scenario);
						for(var i = 0; i < outcomeStrings.length; i++){
							totalCounts = updateCounts(outcomeStrings[i], totalCounts);
							totalMultipliers = updateMultipliers(outcomeStrings[i], totalMultipliers);
						}
						
						debugFeed.push(totalCounts);
						
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
						r.push('<tr class="tablehead">');
						r.push('<td>');
						r.push(getTranslationByName("snowmanValue", translations));
						r.push('</td>');
						r.push('<td>');
						r.push(getTranslationByName("snowmanProgress", translations));
						r.push('</td>');
						r.push('<td>');
						r.push(getTranslationByName("snowmanValueMultiplier", translations));
						r.push('</td>');
						r.push('</tr>');
						for(var i = 0; i< totalCounts.length; i++){
							r.push('<tr class="tablebody">');
							r.push('<td>');
							if(i<5){
								r.push(convertedPrizeValues[prizeList.indexOf(chosenSnowmans[i])]);
								registerDebugText("Snowman " + chosenSnowmans[i] + "has a Value of " + convertedPrizeValues[prizeList.indexOf(chosenSnowmans[i])]);
							} else if(i === 5){
								r.push(getTranslationByName("noValueSnowman", translations) + " 1");
							} else if(i === 6){
								r.push(getTranslationByName("noValueSnowman", translations) + " 2");
							} else if(i === 7){
								r.push(getTranslationByName("noValueSnowman", translations) + " 3");
							}
							r.push('</td>');
							
							
							r.push('<td>');
							r.push(totalCounts[i]);
							if(totalCounts[i] === 10){
								if(i < 5){
									r.push(" (" + getTranslationByName("win", translations) + ")");
								}
							}
							r.push('</td>');
							
							r.push('<td>');
							if(i<5){
								r.push(convertMultiplier(totalMultipliers[i]));
							} else {
								r.push(getTranslationByName("na", translations));
							}
							r.push('</td>');
							
							r.push('</tr>');
						}
						r.push('</table>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
								r.push('</td>');
								r.push('</tr>');
							}
							r.push('</table>');
							
						}
						return r.join('');
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: "23,9,31|8:E,35:E,4:D,13:D,37:G,..."
					// Output: ["23", "9", "31"]
					function getWinningNumbers(scenario)
					{
						var numsData = scenario.split("|")[0];
						return numsData.split("");
					}

					// Input: "23,9,31|8:E,35:E,4:D,13:D,37:G,..."
					// Output: ["8", "35", "4", "13", ...] or ["E", "E", "D", "G", ...]
					function getOutcomeData(scenario, index)
					{
						var outcomeData = scenario.split("|")[1];
						var outcomePairs = outcomeData.split(",");
						var result = [];
						for(var i = 0; i < outcomePairs.length; ++i)
						{
							result.push(outcomePairs[i].split(":")[index]);
						}
						return result;
					}
					
					function getTurnStrings(scenario){
						var outcomeData = scenario.split("|")[1];
						var outcomePairs = outcomeData.split(",");
						return outcomePairs;
					}
					
					function updateCounts(turnString,totalCounts){
						for(var i = 0; i<turnString.length; i++){
							var currChar = turnString.charAt(i);
							if(currChar!=='X'){
								totalCounts[i] += parseInt(currChar);
							}
						}
						return totalCounts;
					}
					
					function updateMultipliers(turnStrings,totalMultipliers){
						for(var i = 0; i<turnStrings.length; i++){
							var currChar = turnStrings.charAt(i);
							if(currChar==='X'){
								totalMultipliers[i] += 1;
							}
						}
						return totalMultipliers;
					}
					
					function convertMultiplier(multiplierValue){
						switch(multiplierValue){
							case 0:
								return "1X";
							case 1:
								return "2X";
							case 2:
								return "4X";
							case 3:
								return "8X";
						}
					}
					
					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.getAttribute("key") == keyName)
							{
								return childNode.getAttribute("value");
							}
							
							index += 2;
						}
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Wager.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<x:variable name="convertedPrizeValues">

					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
