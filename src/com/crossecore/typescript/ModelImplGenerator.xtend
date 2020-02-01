package com.crossecore.typescript;

import com.crossecore.DependencyManager
import com.crossecore.Utils
import com.crossecore.csharp.CSharpOCLVisitor
import java.util.List
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.ETypeParameter
import com.crossecore.ImportManager
import org.eclipse.emf.ecore.EcorePackage
import com.crossecore.TypeTranslator

class ModelImplGenerator extends TypeScriptVisitor{ 
	

	private TypeScriptIdentifier id = new TypeScriptIdentifier();
	private CSharpOCLVisitor ocl2csharp = new CSharpOCLVisitor();
	private TypeTranslator t = new TypeScriptTypeTranslator(id);
	private ImportManager imports = new ImportManager(t);
	
	
	new(){
		super();
	}
	
	new(String path, String filenamePattern, EPackage epackage){
		super(path, filenamePattern, epackage);

	}
		
	
	override caseEPackage (EPackage epackage){
		var List<EClass> sortedEClasses = DependencyManager.sortEClasses(epackage);
		
		for(EClass eclass : sortedEClasses){
			
			imports.clear;
			
			var body = 	
			'''
			«IF !Utils.isEcoreEPackage(epackage)»
			/* import Ecore*/
		 	«ENDIF»
			«doSwitch(eclass)»
			'''
			
			var imports = 
			'''
			«FOR String path : imports.fullyQualifiedImports»
				«IF imports.getPackage(path).nsURI.equals(epackage.nsURI)»
				import {«imports.getLocalName(path)»} from "./«imports.getLocalName(path)»";
				«ELSE»
				import {«imports.getLocalName(path)»} from "«path»";
				«ENDIF»
			«ENDFOR»
			'''
			
			var contents =
			'''
			«imports»
			«body»
			'''
			
			write(eclass, contents, false);
		}
	
		return "";
	}
	
	override write(){
		doSwitch(epackage);
	}
	

	
	override caseEClass(EClass e){

		if(!e.interface){
			
			//TODO what about allInstances on interfaces?
			var closure = Utils.getSubclasses(e);
			
			imports.add(EcorePackage.eINSTANCE, "Set");
			imports.filter(e);
			imports.add(e.EPackage, id.EClassBase(e));
			
			//TODO use importmanager
			'''
			export class «id.EClassImpl(e)»«FOR ETypeParameter param : e.ETypeParameters BEFORE '<' SEPARATOR ',' AFTER '>'»«id.doSwitch(param)»«ENDFOR»
			extends «id.EClassBase(e)»«FOR ETypeParameter param : e.ETypeParameters BEFORE '<' SEPARATOR ',' AFTER '>'»«id.doSwitch(param)»«ENDFOR»
			{
				public static allInstances_:Set<«id.doSwitch(e)»> = new Set<«id.doSwitch(e)»>();
				//implement your generated class here
			}
			'''
		
		}
	
	}

	
	def caseEClass__(EClass e){

		if(!e.interface){
			
			//TODO what about allInstances on interfaces?
			var closure = Utils.getSubclasses(e);
			
			imports.add(EcorePackage.eINSTANCE, "Set");
			imports.filter(e);
			imports.add(e.EPackage, id.EClassBase(e));
			
			//TODO use importmanager
			'''
			export class «id.EClassImpl(e)»«FOR ETypeParameter param : e.ETypeParameters BEFORE '<' SEPARATOR ',' AFTER '>'»«id.doSwitch(param)»«ENDFOR»
			extends «id.EClassBase(e)»«FOR ETypeParameter param : e.ETypeParameters BEFORE '<' SEPARATOR ',' AFTER '>'»«id.doSwitch(param)»«ENDFOR»
			{

				public static allInstances_:Set<«id.doSwitch(e)»> = new Set<«id.doSwitch(e)»>();
					
				public static allInstances():Set<«id.doSwitch(e)»>{
					
					let result = new Set<«id.doSwitch(e)»>();
					«id.EClassImpl(e)».allInstances_.forEach(x => result.push(x));
					
					«FOR s:closure»
					«imports.add(s.EPackage, id.EClassImpl(s))»
					«id.EClassImpl(s)».allInstances_.forEach(x => result.push(x));
					«ENDFOR»
					
					return result;
				}
				
				
				//implement your generated class here
			}
			'''
		
		}
	
	}
	
}